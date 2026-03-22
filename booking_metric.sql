-- My Notes
-- Confirmed = successful
-- Cancelled = unsuccessful
-- Pending = unresolved 
-- Assignments with no booking = unresolved
-- Revenue only counts for confirmed bookings
-- Exclude pending and missing booking cases from win rate 
SELECT
    space_travel_agents.AgentID,
    space_travel_agents.FirstName,
    space_travel_agents.LastName,

    SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
    -- count for confirmed bookings

    SUM(CASE WHEN bookings.BookingStatus = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
    -- count for cancelled bookings

    1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate,
    -- getting the close rate of agents by dividing confirmed / decided
    -- decided means only confirmed or cancelled

    AVG(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN bookings.TotalRevenue END) AS avg_confirmed_revenue,
    -- average revenue from confirmed bookings

    space_travel_agents.AverageCustomerServiceRating
    -- customer service rating from the agent table

FROM space_travel_agents

LEFT JOIN assignment_history
    ON space_travel_agents.AgentID = assignment_history.AgentID
-- join each agent to their assignments

LEFT JOIN bookings
    ON assignment_history.AssignmentID = bookings.AssignmentID
-- join assignments to booking outcomes

GROUP BY
    space_travel_agents.AgentID,
    space_travel_agents.FirstName,
    space_travel_agents.LastName,
    space_travel_agents.AverageCustomerServiceRating
-- group by agent so I get one summary row per agent

ORDER BY
    close_rate DESC,
    avg_confirmed_revenue DESC;
-- organized from best close rate first, then average confirmed revenue