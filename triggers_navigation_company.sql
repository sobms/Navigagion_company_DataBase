CREATE OR REPLACE FUNCTION decommissioned_ship_on_the_voyage() RETURNS TRIGGER AS $$
        DECLARE
        decommission_act_id INTEGER;
        BEGIN
            SELECT ship.act_id INTO decommission_act_id
            FROM ship WHERE ship.imo_number = new.imo_number;
            /*RAISE NOTICE 'decommission_act_id: %', decommission_act_id;*/
            IF (decommission_act_id IS NOT NULL)
            THEN
            RAISE EXCEPTION 'Попытка назначения на рейс списанного судна';
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER DecommissionedShipOnTheVoyage
        AFTER INSERT OR UPDATE ON Ship_assigned_to_voyage
        FOR EACH ROW EXECUTE PROCEDURE decommissioned_ship_on_the_voyage();

CREATE OR REPLACE FUNCTION decommissioned_ship_in_ticket() RETURNS TRIGGER AS $$
        DECLARE
        decommission_act_id INTEGER;
        BEGIN
            SELECT ship.act_id INTO decommission_act_id
            FROM ship WHERE ship.imo_number = new.imo_number;
            IF (decommission_act_id IS NOT NULL)
            THEN
            RAISE EXCEPTION 'Билет на списанное судно';
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER DecommissionedShipInTicket
        AFTER INSERT OR UPDATE ON Ticket
        FOR EACH ROW EXECUTE PROCEDURE decommissioned_ship_in_ticket();

CREATE OR REPLACE FUNCTION decommissioned_ship_in_declaration() RETURNS TRIGGER AS $$
        DECLARE
        decommission_act_id INTEGER;
        BEGIN
            SELECT ship.act_id INTO decommission_act_id
            FROM ship WHERE ship.imo_number = new.imo_number;
            IF (decommission_act_id IS NOT NULL)
            THEN
            RAISE EXCEPTION 'Создание декларации для списанного судна';
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER DecommissionedShipInDeclaration
        AFTER INSERT OR UPDATE ON Ship_declaration
        FOR EACH ROW EXECUTE PROCEDURE decommissioned_ship_in_declaration();

CREATE OR REPLACE FUNCTION adding_new_intermediate_seaport() RETURNS TRIGGER AS $$
    DECLARE
        max_number INTEGER;
        min_number INTEGER;
        new_departure_seaport INTEGER;
        new_destination_seaport INTEGER;
    BEGIN
        SELECT max(intermediate_seaport_of_route.sequence_number) INTO max_number
        FROM intermediate_seaport_of_route WHERE intermediate_seaport_of_route.route_id = new.route_id
                                                 or intermediate_seaport_of_route.route_id = old.route_id;
        SELECT min(intermediate_seaport_of_route.sequence_number) INTO min_number
        FROM intermediate_seaport_of_route WHERE intermediate_seaport_of_route.route_id = new.route_id
                                                 or intermediate_seaport_of_route.route_id = old.route_id;
        /* для insert and update */
        IF (new.sequence_number = min_number)
        THEN
            UPDATE route SET departure_seaport_id = new.seaport_id
            WHERE route_id = new.route_id;
        END IF;
        IF (new.sequence_number = max_number)
        THEN
            UPDATE route SET destination_seaport_id = new.seaport_id
            WHERE route_id = new.route_id;
        END IF;
        /* для delete and update*/

        IF (old.sequence_number < min_number)
        THEN
            SELECT intermediate_seaport_of_route.seaport_id INTO new_departure_seaport
            FROM intermediate_seaport_of_route WHERE
            intermediate_seaport_of_route.sequence_number = min_number
            AND intermediate_seaport_of_route.route_id = old.route_id;

            UPDATE route SET departure_seaport_id = new_departure_seaport
            WHERE route_id = old.route_id; /* так как new не содержит ничего для delete*/
        END IF;
        IF (old.sequence_number > max_number)
        THEN
            SELECT intermediate_seaport_of_route.seaport_id INTO new_destination_seaport
            FROM intermediate_seaport_of_route WHERE
            intermediate_seaport_of_route.sequence_number = max_number
            AND intermediate_seaport_of_route.route_id = old.route_id;

            UPDATE route SET destination_seaport_id = new_destination_seaport
            WHERE route_id = old.route_id;
        END IF;
        RETURN NEW;
    END;
    $$ language plpgsql;
    CREATE TRIGGER AddingNewIntermediateSeaport
    AFTER INSERT OR UPDATE OR DELETE ON intermediate_seaport_of_route
    FOR EACH ROW EXECUTE PROCEDURE adding_new_intermediate_seaport();

CREATE OR REPLACE FUNCTION decommission_act_date_check() RETURNS TRIGGER AS $$
    DECLARE
        decommissioning_date_var date;
    BEGIN
        SELECT decommissioning_date INTO decommissioning_date_var
        FROM ship_decommissioning_act WHERE act_id = new.act_id;
        if decommissioning_date_var IS NOT NULL AND new.release_date >= decommissioning_date_var
        THEN
            RAISE EXCEPTION 'Дата списания судна предшествует дате выпуска';
        end if;
        RETURN NEW;
    end;



    $$ language plpgsql;
    CREATE TRIGGER DecommissionActDateCheck
    AFTER INSERT OR UPDATE ON ship
    FOR EACH ROW EXECUTE PROCEDURE decommission_act_date_check();

CREATE OR REPLACE FUNCTION check_tonnage_exceeding() RETURNS  TRIGGER AS $$
DECLARE
    current_cargo_weight integer;
    route                integer;
    c_cursor             refcursor;
    cur_point          integer;
    ship_tonnage         integer;
    add_weight           integer;
    minus_weight         integer;
BEGIN
    /*choose route from voyage*/
    SELECT DISTINCT (voyage.route_id)
    INTO route
    FROM voyage
    WHERE voyage.voyage_id = new.voyage_id;
    raise notice 'route_id: %', route;
    /*choose tonnage from cargo_ship*/
    SELECT cargo_ship.tonnage
    INTO ship_tonnage
    FROM cargo_ship
    WHERE cargo_ship.imo_number = new.imo_number;
    raise notice 'tonnage: %', ship_tonnage;

    OPEN c_cursor FOR SELECT intermediate_seaport_of_route.sequence_number
                      FROM intermediate_seaport_of_route
                      WHERE intermediate_seaport_of_route.route_id = route
                      ORDER BY intermediate_seaport_of_route.sequence_number;

    current_cargo_weight = 0;
    raise notice 'current_cargo_weight: %', current_cargo_weight;
    LOOP
        FETCH c_cursor INTO cur_point;
        if (cur_point = new.destination_port_number_in_route)
        THEN
            EXIT;
        end if;
        /*loading*/
        SELECT sum(ship_declaration.tonnage)
        INTO add_weight
        FROM ship_declaration
        WHERE ship_declaration.imo_number = new.imo_number
          AND ship_declaration.voyage_id = new.voyage_id
          AND ship_declaration.departure_port_number_in_route = cur_point;
        /*unloading*/
        SELECT sum(ship_declaration.tonnage)
        INTO minus_weight
        FROM ship_declaration
        WHERE ship_declaration.imo_number = new.imo_number
          AND ship_declaration.voyage_id = new.voyage_id
          AND ship_declaration.destination_port_number_in_route = cur_point;
        if minus_weight is null
        then
            minus_weight = 0;
        end if;
        if add_weight is null
        then
            add_weight = 0;
        end if;
        current_cargo_weight = current_cargo_weight + add_weight - minus_weight;

        raise notice 'current_cargo_weight: %', current_cargo_weight;

        IF (current_cargo_weight > ship_tonnage)
        THEN
            RAISE EXCEPTION 'Превышен тоннаж судна';
        END IF;
    end loop;
    RETURN NEW;
END;
$$ language plpgsql;
CREATE TRIGGER CheckTonnageExceeding
AFTER INSERT OR UPDATE ON ship_declaration
FOR EACH ROW EXECUTE PROCEDURE check_tonnage_exceeding();

CREATE OR REPLACE FUNCTION check_count_of_tickets () RETURNS TRIGGER AS $$
DECLARE
    ticket_route_id integer;
    c_cursor        refcursor;
    stateroom_num   integer;
    ship_capacity   integer;
    cur_point       integer;
    current_fullness integer;
    landing_people  integer;
    disembarked_people integer;
BEGIN
    current_fullness = 0;
    /* choose ticket_route_id */
    SELECT route_id INTO ticket_route_id
    FROM voyage WHERE voyage.voyage_id = new.voyage_id;
    /* choose number of stateroom such class */
    SELECT stateroom_number INTO stateroom_num
    FROM passenger_ship_capacity
    WHERE imo_number = new.imo_number AND class_name = new.class_name;
    /* choose stateroom_capacity*/
    SELECT capacity INTO ship_capacity
    FROM stateroom_class
    WHERE class_name = new.class_name;
    /* count ship capacity */
    ship_capacity = ship_capacity * stateroom_num;

    OPEN c_cursor FOR SELECT intermediate_seaport_of_route.sequence_number
                      FROM intermediate_seaport_of_route
                      WHERE intermediate_seaport_of_route.route_id = ticket_route_id
                      ORDER BY intermediate_seaport_of_route.sequence_number;
    LOOP
        FETCH c_cursor INTO cur_point;
        raise notice 'cur_point %', cur_point;
        if (cur_point = new.destination_port_number_in_route) or cur_point is null
        THEN
            EXIT;
        end if;

        /*landing*/
        SELECT count(*)
        INTO landing_people
        FROM ticket
        WHERE imo_number = new.imo_number
          AND voyage_id = new.voyage_id
          AND class_name = new.class_name
          AND departure_port_number_in_route = cur_point;
        /*disembarkation*/
        SELECT count(*)
        INTO disembarked_people
        FROM ticket
        WHERE imo_number = new.imo_number
          AND voyage_id = new.voyage_id
          AND class_name = new.class_name
          AND destination_port_number_in_route = cur_point;
        if disembarked_people is null
        then
            disembarked_people = 0;
        end if;
        if landing_people is null
        then
            landing_people = 0;
        end if;
        current_fullness = current_fullness - disembarked_people + landing_people;
        raise notice 'current_fullness: %', current_fullness;
        IF (current_fullness > ship_capacity)
        THEN
            RAISE EXCEPTION 'Мест в каютах данного класса на данный рейс нет!';
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ language plpgsql;
CREATE TRIGGER CheckCountOfTickets
AFTER INSERT OR UPDATE ON ticket
FOR EACH ROW EXECUTE PROCEDURE check_count_of_tickets();

/*CREATE OR REPLACE FUNCTION check_route_voyage_compliance_in_ticket () RETURNS TRIGGER AS $$
    BEGIN
        if (new.route_id, new.voyage_id) not in (select route_id, voyage_id from voyage)
        then
            RAISE EXCEPTION 'Не существует такой пары рейс-маршрут для route: %, voyage: %',
                new.route_id, new.voyage_id;
        end if;
        RETURN NEW;
    end;
$$ language plpgsql;
CREATE TRIGGER CheckRouteVoyageComplianceInTicket
AFTER INSERT OR UPDATE ON ticket
FOR EACH ROW EXECUTE PROCEDURE check_route_voyage_compliance_in_ticket();

CREATE OR REPLACE FUNCTION check_route_voyage_compliance_in_declaration () RETURNS TRIGGER AS $$
    BEGIN
        if (new.route_id, new.voyage_id) not in (select route_id, voyage_id from voyage)
        then
            RAISE EXCEPTION 'Не существует такой пары рейс-маршрут для route: %, voyage: %',
                new.route_id, new.voyage_id;
        end if;
        RETURN NEW;
    end;
$$ language plpgsql;
CREATE TRIGGER CheckRouteVoyageComplianceInDeclaration
AFTER INSERT OR UPDATE ON ticket
FOR EACH ROW EXECUTE PROCEDURE check_route_voyage_compliance_in_declaration();*/