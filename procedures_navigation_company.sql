CREATE OR REPLACE PROCEDURE tickets_release_on_new_voyage (
    voyage_id_              integer,
    ship_imo_number         integer
) AS $$
    DECLARE
        route_id_           integer;
        dest_port_num       integer;
        start_port_num      integer;
        c_cursor            refcursor;
        class_c             class_name_enum;
        capacity_c          integer;
        stateroom_number_c  integer;
        tickets_count       integer;
    BEGIN
        SELECT DISTINCT(route_id) INTO route_id_
        FROM voyage WHERE voyage_id = voyage_id_;
        SELECT max(sequence_number) INTO dest_port_num
        FROM intermediate_seaport_of_route WHERE route_id = route_id_;
        SELECT min(sequence_number) INTO start_port_num
        FROM intermediate_seaport_of_route WHERE route_id = route_id_;

        OPEN c_cursor FOR   SELECT t.class_name, t.capacity, p.stateroom_number FROM
                            passenger_ship_capacity AS p JOIN stateroom_class AS t
                            ON t.class_name = p.class_name
                            WHERE p.imo_number = ship_imo_number;
        LOOP
            FETCH c_cursor INTO class_c, capacity_c, stateroom_number_c;
            if class_c is null
            THEN
                EXIT;
            end if;
            raise notice '% % %', class_c, capacity_c, stateroom_number_c;
            tickets_count = (capacity_c * stateroom_number_c) - (SELECT count(*) FROM ticket
            WHERE class_name = class_c and voyage_id=voyage_id_ and imo_number=ship_imo_number);
            FOR i in 1..tickets_count LOOP
                INSERT INTO ticket(voyage_id, class_name, route_id, destination_port_number_in_route, departure_port_number_in_route, price, imo_number)
                VALUES (voyage_id_, class_c, route_id_, dest_port_num, start_port_num, 0, ship_imo_number);
            end loop;
        END LOOP;
    END;

$$ language plpgsql;

CREATE OR REPLACE PROCEDURE count_tickets_prices_on_new_voyage (
    new_voyage_id           integer,
    ship_imo_number         integer
) AS $$
    DECLARE
        c_cursor            refcursor;
        ticket_id           integer;
        stateroom_class_    class_name_enum;
        route_id_           integer;
        dest_port_num       integer;
        start_port_num      integer;
        basic_price         integer;
        capacity_           integer;
        total_dist          integer;
        total_ship_capacity integer;
        count_of_ports      integer;
        total_shipping_cost integer;
        t_price               integer;
        points_in_route_count integer;
    BEGIN
        RAISE NOTICE 'start % % %', ship_imo_number, new_voyage_id,
            (SELECT COUNT(*) FROM ticket WHERE imo_number = ship_imo_number AND voyage_id = new_voyage_id);
        OPEN c_cursor FOR SELECT ticket_number, class_name, route_id, destination_port_number_in_route, departure_port_number_in_route
                      FROM ticket WHERE imo_number = ship_imo_number AND voyage_id = new_voyage_id;
        FOR i in 1..(SELECT COUNT(*) FROM ticket WHERE imo_number = ship_imo_number AND voyage_id = new_voyage_id) LOOP
            FETCH c_cursor INTO
            ticket_id, stateroom_class_, route_id_, dest_port_num, start_port_num;
            RAISE NOTICE '%', i;
            if ticket_id is null or dest_port_num <= start_port_num
            THEN
                Continue;
            end if;

            SELECT basic_rental_price, capacity INTO basic_price, capacity_
            FROM stateroom_class WHERE class_name = stateroom_class_;
            SELECT total_distance INTO total_dist FROM voyage WHERE voyage_id = new_voyage_id;
            SELECT sum(t.capacity*p.stateroom_number) INTO total_ship_capacity FROM
            passenger_ship_capacity AS p JOIN stateroom_class AS t
            ON t.class_name = p.class_name
            WHERE p.imo_number = ship_imo_number;
            SELECT count(*) INTO count_of_ports FROM intermediate_seaport_of_route
            WHERE route_id= route_id_;
            SELECT sum(shipping_cost), count(*)
            INTO total_shipping_cost, points_in_route_count
            FROM intermediate_seaport_of_route AS t JOIN seaport AS s
            ON t.seaport_id = s.seaport_id
            WHERE route_id = route_id_ and sequence_number >= start_port_num and sequence_number<= dest_port_num;
            t_price = total_shipping_cost/total_ship_capacity + basic_price/capacity_ +
                    points_in_route_count/count_of_ports*total_dist*10;
            UPDATE ticket SET price = t_price WHERE  ticket_number = ticket_id;
            raise notice 'total_shipping_cost: %, 2-part: %', total_shipping_cost, points_in_route_count;
        end loop;
    END;
        /*price = basic_rental_price/stateroom_capacity +
          ticket_route_points_count/all_route_points_count*distance*10 +
          sum(shipping_cost/total_ship_capacity)
         */


$$ language plpgsql;

