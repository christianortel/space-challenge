-- Testing tables loaded properly
SELECT COUNT(*) AS agent_count
FROM space_travel_agents;

SELECT COUNT(*) AS assignment_count
FROM assignment_history;

SELECT COUNT(*) AS booking_count
FROM bookings;

-- Counting bookings status
SELECT BookingStatus, 
COUNT(*) AS cnt
FROM bookings
GROUP BY BookingStatus
ORDER BY cnt DESC;
-- Confirmed = 297
-- Cancelled = 95
-- Pending = 20

-- Checking communication methods
SELECT CommunicationMethod, 
COUNT(*) AS cnt
FROM assignment_history
GROUP BY CommunicationMethod
ORDER BY cnt DESC;
-- Texting = 296
-- Phone Call = 154

-- Checking lead sources
SELECT LeadSource, 
COUNT(*) AS cnt
FROM assignment_history
GROUP BY LeadSource
ORDER BY cnt DESC;
-- Organic = 231
-- Bought = 219

-- Checking destinations
SELECT Destination, 
COUNT(*) AS cnt
FROM bookings
GROUP BY Destination
ORDER BY cnt DESC;
-- Mars = 105
-- Europa = 103
-- Venus = 98
-- Titan = 97
-- Ganymede = 9

-- Checking launch locations in bookings can effect agent performance
SELECT LaunchLocation, 
COUNT(*) AS cnt
FROM bookings
GROUP BY LaunchLocation
ORDER BY cnt DESC;
-- Dallas = 104
-- NY = 101
-- Dubai = 101
-- Tokyo = 98
-- London = 7
-- Sydney = 1

-- How many assignments dont have a booking?
SELECT COUNT(*) AS assignments_without_booking
FROM assignment_history a
LEFT JOIN bookings b
    ON a.AssignmentID = b.AssignmentID
WHERE b.AssignmentID IS NULL;
-- No booking = 38


