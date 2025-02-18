--CREATE VIEW vRequests
--AS
SELECT 
	d.name as 'database_name'
	, s.login_name
	, r.session_id
	, r.start_time
	, r.status
	, r.total_elapsed_time
	, r.command
	,CASE   --uses statement start and end offset to figure out what statement is running
	WHEN r.[statement_start_offset] > 0 THEN  
	--The start of the active command is not at the beginning of the full command text 
	CASE r.[statement_end_offset]  
		WHEN -1 THEN  
			--The end of the full command is also the end of the active statement 
			SUBSTRING(t.TEXT, (r.[statement_start_offset]/2) + 1, 2147483647) 
		ELSE   
			--The end of the active statement is not at the end of the full command 
			SUBSTRING(t.TEXT, (r.[statement_start_offset]/2) + 1, (r.[statement_end_offset] - r.[statement_start_offset])/2)   
	END  
	ELSE  
	--1st part of full command is running 
	CASE r.[statement_end_offset]  
		WHEN -1 THEN  
			--The end of the full command is also the end of the active statement 
			RTRIM(LTRIM(t.[text]))  
		ELSE  
			--The end of the active statement is not at the end of the full command 
			LEFT(t.TEXT, (r.[statement_end_offset]/2) +1)  
	END  
	END 
	AS [executing_statement] 
	,t.[text] AS [parent_batch] 
	, s.program_name
	, r.query_hash
	, r.query_plan_hash
	, r.dist_statement_id
	, r.label
	, s.client_interface_name
	,r.sql_handle
	,c.client_net_address
	,c.connection_id
FROM sys.dm_exec_requests r 
CROSS APPLY sys.[dm_exec_sql_text](r.[sql_handle]) t  
JOIN sys.dm_exec_sessions s
	ON r.session_id = s.session_id
JOIN sys.dm_exec_connections c
	ON s.session_id = c.session_id
JOIN sys.databases d
	ON d.database_id = r.database_id
WHERE r.dist_statement_id != '00000000-0000-0000-0000-000000000000' 
AND r.session_id <> @@SPID 
AND s.program_name NOT IN ('QueryInsights','DMS')