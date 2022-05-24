/* count total profit for voyage which is starting yesterday */
SELECT SUM(price) as total_profit
FROM voyage AS V JOIN ticket AS T
ON V.voyage_id = T.voyage_id
WHERE departure_date = '18-05-2022';

/* full names of clients who bought tickets on ship which is attacked by rebels in this year */
SELECT full_name, internal_account FROM client AS C
    JOIN fact_of_ticket_purchase AS F ON C.client_id = F.client_id
    JOIN ticket AS T ON F.ticket_number = T.ticket_number
    JOIN ship AS S ON T.imo_number = S.imo_number
    JOIN voyage AS V ON T.voyage_id = V.voyage_id
    WHERE status = 'захвачен пиратами' AND departure_date > '2021-05-19';



/* output the route which total profit was a minimum for last year */
WITH L AS (
    SELECT V.route_id, coalesce(SUM(S.price),0)+coalesce(SUM(T.Price),0)
	as total_profit FROM
	ship_declaration AS S
	FULL OUTER JOIN ticket AS T
	ON S.voyage_id = T.voyage_id
	JOIN voyage AS V ON V.voyage_id = T.voyage_id OR V.voyage_id = S.voyage_id
	WHERE V.departure_date > '2021-05-19'
    GROUP BY V.route_id
)
SELECT R.*, total_profit FROM route AS R
JOIN L ON R.route_id = L.route_id
WHERE R.route_id =
(SELECT route_id FROM L
 WHERE total_profit = (SELECT MIN(total_profit) FROM L));

/*count total tonnage during the last day voyages for all ships which was in voyages and output*/
WITH L AS (
	select S.imo_number, max(arrival_date) as last_voyage_date
	from voyage AS V JOIN ship_assigned_to_voyage AS S
	ON V.voyage_id = S.voyage_id
	group by imo_number
)
SELECT L.imo_number, coalesce(SUM(tonnage), 0) as total_tonnage_per_last_voyage
from voyage AS V
JOIN ship_assigned_to_voyage AS S
ON V.voyage_id = S.voyage_id
join L ON S.imo_number = L.imo_number
left outer join ship_declaration AS SD
ON V.voyage_id = SD.voyage_id and L.imo_number = SD.imo_number
WHERE V.arrival_date = L.last_voyage_date
Group by L.imo_number;

/*find ships which travel only from port1*/
SELECT S.* FROM ship AS S
JOIN ship_assigned_to_voyage SATV ON S.imo_number = SATV.imo_number
JOIN voyage AS V ON SATV.voyage_id = V.voyage_id
JOIN route AS R ON V.route_id = R.route_id
JOIN seaport AS SP ON SP.seaport_id = R.departure_seaport_id
WHERE SP.name = 'Анапа'
EXCEPT
SELECT S.* FROM ship AS S
JOIN ship_assigned_to_voyage AS SATV ON S.imo_number = SATV.imo_number
JOIN voyage AS V ON SATV.voyage_id = V.voyage_id
JOIN route AS R ON V.route_id = R.route_id
JOIN seaport AS SP ON SP.seaport_id = R.departure_seaport_id
WHERE SP.name != 'Анапа';

/*find ships which travel only from port1 and more than n times */
SELECT S.* FROM ship AS S
JOIN ship_assigned_to_voyage SATV ON S.imo_number = SATV.imo_number
JOIN voyage AS V ON SATV.voyage_id = V.voyage_id
JOIN route AS R ON V.route_id = R.route_id
JOIN seaport AS SP ON SP.seaport_id = R.departure_seaport_id
WHERE SP.name = 'Анапа'
Group by S.imo_number
HAVING count(*) > 3
EXCEPT
SELECT S.* FROM ship AS S
JOIN ship_assigned_to_voyage AS SATV ON S.imo_number = SATV.imo_number
JOIN voyage AS V ON SATV.voyage_id = V.voyage_id
JOIN route AS R ON V.route_id = R.route_id
JOIN seaport AS SP ON SP.seaport_id = R.departure_seaport_id
WHERE SP.name != 'Анапа';