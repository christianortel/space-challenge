SELECT
    space_travel_agents.AgentID,
    space_travel_agents.FirstName,
    space_travel_agents.LastName,

    ROUND(
        0.70 * base_metrics.close_rate
        -- 70% weight on the agents overall close rate

        + 0.20 * (
            (
                CASE
                    WHEN method_history.decided_count >= 2 THEN method_history.close_rate
                    ELSE base_metrics.close_rate
                END
                -- will use communication method close rate if enough history exists
                -- if not fall back to overall close rate
                +
                CASE
                    WHEN source_history.decided_count >= 2 THEN source_history.close_rate
                    ELSE base_metrics.close_rate
                END
                -- same logic for lead source
                +
                CASE
                    WHEN destination_history.decided_count >= 2 THEN destination_history.close_rate
                    ELSE base_metrics.close_rate
                END
                -- same logic for destination
                +
                CASE
                    WHEN launch_history.decided_count >= 2 THEN launch_history.close_rate
                    ELSE base_metrics.close_rate
                END
                -- same logic for launch location

            ) / 4.0
        )
        -- average the 4 lead fit checks
        -- this whole section gets 20% of the final score

        + 0.10 * (space_travel_agents.AverageCustomerServiceRating / 5.0)
        -- 10% weight on customer service rating
        -- divide by 5 so it is on a similar scale as close rate

        , 4
    ) AS final_score,
    -- final weighted score used for ranking

    ROUND(base_metrics.close_rate, 4) AS overall_close_rate,
    -- overall close rate across all bookings

    ROUND(space_travel_agents.AverageCustomerServiceRating, 2) AS customer_service_rating,
    -- customer service score from the agents table

    ROUND(base_metrics.avg_confirmed_revenue, 2) AS avg_confirmed_revenue
    -- average revenue from confirmed bookings only

FROM space_travel_agents

CROSS JOIN (
    SELECT
        'Test Customer' AS CustomerName,
        'Phone Call' AS CommunicationMethod,
        'Organic' AS LeadSource,
        'Mars' AS Destination,
        'Dallas-Fort Worth Launch Complex' AS LaunchLocation
) input_lead
-- change inputs here to test different scenarios

LEFT JOIN (
    SELECT
        space_travel_agents.AgentID,

        1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate,
        -- overall close rate = confirmed / decided
        -- decided means confirmed or cancelled only

        AVG(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN bookings.TotalRevenue END) AS avg_confirmed_revenue
        -- revenue only counts for confirmed bookings

    FROM space_travel_agents

    LEFT JOIN assignment_history
        ON space_travel_agents.AgentID = assignment_history.AgentID
    -- connect agents to their assignments

    LEFT JOIN bookings
        ON assignment_history.AssignmentID = bookings.AssignmentID
    -- connect assignments to booking outcomes

    GROUP BY
        space_travel_agents.AgentID
    -- one summary row per agent
) base_metrics
    ON space_travel_agents.AgentID = base_metrics.AgentID
-- join overall performance back to each agent

LEFT JOIN (
    SELECT
        assignment_history.AgentID,
        assignment_history.CommunicationMethod,

        SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END) AS decided_count,
        -- count decided records for this agent + communication method

        1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate
        -- close rate for this specific communication method

    FROM assignment_history

    LEFT JOIN bookings
        ON assignment_history.AssignmentID = bookings.AssignmentID

    GROUP BY
        assignment_history.AgentID,
        assignment_history.CommunicationMethod
    -- one row per agent + communication method
) method_history
    ON space_travel_agents.AgentID = method_history.AgentID
   AND input_lead.CommunicationMethod = method_history.CommunicationMethod
-- only bring in the row matching this lead's communication method

LEFT JOIN (
    SELECT
        assignment_history.AgentID,
        assignment_history.LeadSource,

        SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END) AS decided_count,
        -- count decided records for this agent + lead source

        1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate
        -- close rate for this specific lead source

    FROM assignment_history

    LEFT JOIN bookings
        ON assignment_history.AssignmentID = bookings.AssignmentID

    GROUP BY
        assignment_history.AgentID,
        assignment_history.LeadSource
    -- one row per agent + lead source
) source_history
    ON space_travel_agents.AgentID = source_history.AgentID
   AND input_lead.LeadSource = source_history.LeadSource
-- only bring in the row matching this leads lead source

LEFT JOIN (
    SELECT
        assignment_history.AgentID,
        bookings.Destination,

        SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END) AS decided_count,
        -- count decided records for this agent and destination

        1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate
        -- close rate for this specific destination

    FROM assignment_history

    LEFT JOIN bookings
        ON assignment_history.AssignmentID = bookings.AssignmentID

    GROUP BY
        assignment_history.AgentID,
        bookings.Destination
    -- one row per agent and destination
) destination_history
    ON space_travel_agents.AgentID = destination_history.AgentID
   AND input_lead.Destination = destination_history.Destination
-- only bring in the row matching this lead's destination

LEFT JOIN (
    SELECT
        assignment_history.AgentID,
        bookings.LaunchLocation,

        SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END) AS decided_count,
        -- count decided records for this agent + launch location

        1.0 * SUM(CASE WHEN bookings.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN bookings.BookingStatus IN ('Confirmed', 'Cancelled') THEN 1 ELSE 0 END), 0) AS close_rate
        -- close rate for this specific launch location

    FROM assignment_history

    LEFT JOIN bookings
        ON assignment_history.AssignmentID = bookings.AssignmentID

    GROUP BY
        assignment_history.AgentID,
        bookings.LaunchLocation
) launch_history
    ON space_travel_agents.AgentID = launch_history.AgentID
   AND input_lead.LaunchLocation = launch_history.LaunchLocation
-- only bring in the row matching this leads launch location

ORDER BY
    final_score DESC,
    avg_confirmed_revenue DESC,
    overall_close_rate DESC;