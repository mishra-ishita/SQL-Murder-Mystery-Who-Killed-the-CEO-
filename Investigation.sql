SELECT * FROM employees;
SELECT * FROM keycard_logs;
SELECT * FROM calls;
SELECT * FROM alibis;
SELECT * FROM evidence;

-- 1. Identify where and when the crime happened
SELECT
    room AS crime_location,
    entry_time AS crime_time
FROM keycard_logs
WHERE room = 'CEO Office'
ORDER BY entry_time;

-- 2. Analyze who accessed critical areas at the time
SELECT 
    k.employee_id, 
    e.name, 
    k.room, 
    k.entry_time, 
    k.exit_time
FROM keycard_logs k
JOIN employees e 
    ON k.employee_id = e.employee_id
WHERE 
    k.room = 'CEO Office'
    AND k.entry_time BETWEEN '2025-10-15 20:00:00' 
                         AND '2025-10-15 21:15:00'
ORDER BY 
    k.entry_time;

-- 3. Cross-check alibis with actual logs
SELECT 
    e.employee_id, 
    e.name, 
    a.claimed_location, 
    k.room AS actual_room, 
    a.claim_time, 
    k.entry_time, 
    k.exit_time,
    CASE
        WHEN k.room IS NULL THEN 'no log available for claim'
        WHEN k.room = a.claimed_location THEN 'Match'
        ELSE 'Mismatch'
    END AS status
FROM employees e 
JOIN alibis a 
    ON e.employee_id = a.employee_id
LEFT JOIN keycard_logs k 
    ON k.employee_id = e.employee_id
    AND a.claim_time BETWEEN k.entry_time AND k.exit_time
ORDER BY e.employee_id;

-- 4. Investigate suspicious calls made around the time
SELECT
    c.call_id,
    e1.name AS caller_name,
    e2.name AS receiver_name,
    c.call_time,
    c.duration_sec
FROM calls AS c
JOIN employees AS e1
    ON c.caller_id = e1.employee_id
JOIN employees AS e2
    ON c.receiver_id = e2.employee_id
WHERE
    c.call_time BETWEEN '2025-10-15 20:00:00' AND '2025-10-15 21:00:00';

-- 5. Match evidence with movements and claims
SELECT
    ev.evidence_id,
    ev.room AS evidence_room,
    ev.description,
    TIME(ev.found_time) AS found_time,
    e.name,
    k.room AS actual_location,
    TIME(k.entry_time) AS entry_time,
    a.claimed_location,
    TIME(a.claim_time) AS claim_time,
    CASE 
        WHEN a.claimed_location IS NULL THEN 'Alibi not available'
        WHEN a.claimed_location = k.room THEN 'Alibi match'
        ELSE 'Alibi mismatch'
    END AS alibi_status
FROM evidence ev
JOIN keycard_logs k 
    ON ev.room = k.room
JOIN employees e 
    ON k.employee_id = e.employee_id
LEFT JOIN alibis a 
    ON e.employee_id = a.employee_id;

-- 6. Combine all findings to identify the killer
SELECT
    emp.name AS suspect,
    k.room AS actual_location,
    TIME(k.entry_time) AS entry_time,
    TIME(k.exit_time) AS exit_time,
    a.claimed_location,
    TIME(a.claim_time) AS claim_time,
    evi.room AS evidence_room,
    evi.description AS evidence_found,
    TIME(evi.found_time) AS evidence_found_time,
    CASE
        WHEN a.claimed_location IS NULL THEN 'No alibi'
        WHEN a.claimed_location = k.room THEN 'Alibi matches'
        ELSE 'Alibi mismatch'
    END AS alibi_status
FROM employees emp
JOIN keycard_logs k
    ON emp.employee_id = k.employee_id
JOIN evidence evi
    ON evi.room = k.room
    AND DATE(evi.found_time) = DATE(k.entry_time)
LEFT JOIN alibis a
    ON a.employee_id = emp.employee_id
    AND DATE(a.claim_time) = DATE(k.entry_time)
WHERE evi.room = 'CEO Office'
ORDER BY evi.found_time, emp.name;