CREATE TABLE Capitan
(
    capitan_id                     SERIAL     NOT NULL PRIMARY KEY,
    Work_experience                            SMALLINT    NOT NULL CHECK (Work_experience >= 0),
    Full_name                             VARCHAR(50) NOT NULL,
    Passport_number                  CHAR(6)     NOT NULL,
    CHECK (Passport_number SIMILAR TO '\d{6}'),
    Passport_series                  CHAR(4)     NOT NULL,
    CHECK (Passport_series SIMILAR TO '\d{4}'),
    UNIQUE (Passport_series, Passport_number),
    Permission_to_ship_management BOOLEAN     NOT NULL
);

CREATE TABLE Ship_decommissioning_act
(
    Act_id    SERIAL NOT NULL PRIMARY KEY,
    Decommissioning_date DATE    NOT NULL
);

CREATE TYPE Ship_type_enum AS ENUM ('Accompanying_ship', 'Target_ship');
CREATE TYPE Status_enum AS ENUM ('в рейсе', 'на ремонте', 'в доках компании', 'захвачен пиратами');
CREATE TYPE Ship_class_enum AS ENUM ('Passenger_ship', 'Cargo_ship');

CREATE TABLE Ship
(
    IMO_number   INTEGER     NOT NULL PRIMARY KEY,
    Name    VARCHAR(60),
    capitan_id INTEGER     NOT NULL REFERENCES Capitan
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    Ship_type Ship_type_enum NOT NULL,
    Release_date DATE,
    Maintenance_price_per_year INTEGER,
    CHECK(Maintenance_price_per_year >= 0),
    Status Status_enum,
    Act_id INTEGER REFERENCES Ship_decommissioning_act
                                                        ON DELETE RESTRICT
                                                        ON UPDATE CASCADE,
    Ship_class Ship_class_enum NOT NULL
);

CREATE TABLE Passenger_ship
(
    IMO_number INTEGER NOT NULL PRIMARY KEY REFERENCES Ship
                               ON DELETE RESTRICT
                               ON UPDATE CASCADE
);

CREATE TABLE Cargo_ship
(
    IMO_number INTEGER NOT NULL PRIMARY KEY REFERENCES Ship
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    Tonnage    INTEGER CHECK (Tonnage >= 0)
);

CREATE TABLE Seaport
(
    Seaport_id SERIAL NOT NULL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Country  VARCHAR(30),
    City VARCHAR(40),
    UNIQUE(Name, Country, City),
    Cost_of_stay_per_day INTEGER CHECK(Cost_of_stay_per_day >= 0),
    Shipping_cost INTEGER CHECK(Shipping_cost >= 0),
    Longitude FLOAT NOT NULL,
    CHECK (Longitude >= -180 AND Longitude <= 180),
    Latitude FLOAT NOT NULL,
    CHECK (Latitude >= -90 AND Latitude <= 90)
);

CREATE TABLE Route
(
    Route_id SERIAL NOT NULL PRIMARY KEY,
    Destination_seaport_id INTEGER NOT NULL REFERENCES Seaport
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Departure_seaport_id INTEGER NOT NULL REFERENCES Seaport
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE
);

CREATE INDEX Route_index ON Route (Destination_seaport_id, Departure_seaport_id);

CREATE TABLE Intermediate_seaport_of_route
(
    Sequence_number INTEGER NOT NULL CHECK(Sequence_number >= 0),
    Route_id INTEGER NOT NULL REFERENCES Route
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,
    PRIMARY KEY (Sequence_number, Route_id),
    Seaport_id INTEGER NOT NULL REFERENCES Seaport
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE
);

CREATE TABLE Voyage
(
    Voyage_id INTEGER NOT NULL PRIMARY KEY,
    CHECK (Voyage_id >= 0),
    Route_id  INTEGER NOT NULL REFERENCES Route
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Departure_date DATE NOT NULL,
    Arrival_date DATE NOT NULL,
    CHECK(Arrival_date >= Departure_date),
    UNIQUE (Route_id, Departure_date, Arrival_date),
    Total_distance INTEGER CHECK (Total_distance >= 0)
);

CREATE TABLE Ship_assigned_to_voyage
(
    IMO_number INTEGER NOT NULL REFERENCES Ship
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Voyage_id INTEGER NOT NULL REFERENCES Voyage
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    PRIMARY KEY (IMO_number, Voyage_id)
);

CREATE TYPE Class_name_enum AS ENUM('эконом', 'бизнес', 'люкс');

CREATE TABLE Stateroom_class
(
    Class_name Class_name_enum NOT NULL PRIMARY KEY,
    Capacity INTEGER NOT NULL CHECK (Capacity >= 0),
    Basic_rental_price INTEGER NOT NULL,
    CHECK (Basic_rental_price >= 0)
);

CREATE TABLE Passenger_ship_capacity
(
    Class_name Class_name_enum NOT NULL REFERENCES Stateroom_class
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    IMO_number   INTEGER     NOT NULL REFERENCES Passenger_ship
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    PRIMARY KEY (Class_name, IMO_number),
    Stateroom_number INTEGER NOT NULL CHECK(Stateroom_number >= 0)
);



CREATE TABLE Ticket
(
    Ticket_number SERIAL NOT NULL PRIMARY KEY,
    CHECK (Ticket_number >= 0),
    Voyage_id INTEGER NOT NULL REFERENCES Voyage
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Class_name Class_name_enum NOT NULL REFERENCES Stateroom_class
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    Route_id INTEGER NOT NULL,
    Destination_port_number_in_route INTEGER NOT NULL,
    FOREIGN KEY (Route_id, Destination_port_number_in_route)
                                        REFERENCES Intermediate_seaport_of_route (route_id, sequence_number)
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Departure_port_number_in_route INTEGER NOT NULL,
    FOREIGN KEY (Route_id, Departure_port_number_in_route)
                                        REFERENCES Intermediate_seaport_of_route (route_id, sequence_number)
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Check (Destination_port_number_in_route > Departure_port_number_in_route),
    Price INTEGER NOT NULL CHECK (Price >= 0), /*как ослаться на базовую стоимость каюты в default*/
    IMO_number INTEGER NOT NULL REFERENCES Passenger_ship
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);

CREATE INDEX ticket_route_index ON Ticket (Route_id, Destination_port_number_in_route, Departure_port_number_in_route);

CREATE TABLE Client
(
    Client_id SERIAL NOT NULL PRIMARY KEY,
    Full_name VARCHAR(50) NOT NULL,
    Passport_number                  CHAR(6)     NOT NULL,
    CHECK (Passport_number SIMILAR TO '\d{6}'),
    Passport_series                  CHAR(4)     NOT NULL,
    CHECK (Passport_series SIMILAR TO '\d{4}'),
    UNIQUE (Passport_series, Passport_number),
    Internal_account VARCHAR(30) NOT NULL UNIQUE,
    Photo VARCHAR(200) NOT NULL UNIQUE
);


CREATE TABLE Fact_of_ticket_purchase
(
    Client_id INTEGER NOT NULL REFERENCES Client
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Ticket_number INTEGER NOT NULL REFERENCES Ticket
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    PRIMARY KEY (Client_id, Ticket_number),
    UNIQUE (Ticket_number)
);

CREATE TABLE Cargo_type
(
    Type_name VARCHAR(30) NOT NULL PRIMARY KEY,
    Cost_of_transportation_per_1_ton INTEGER NOT NULL,
    CHECK (Cost_of_transportation_per_1_ton >= 0),
    List_of_products TEXT NOT NULL
);

CREATE TABLE Ship_declaration
(
      Declaration_id SERIAL NOT NULL PRIMARY KEY,
      Type_name VARCHAR(30) NOT NULL REFERENCES cargo_type
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Route_id INTEGER NOT NULL,
      Destination_port_number_in_route INTEGER NOT NULL,
      FOREIGN KEY (Route_id, Destination_port_number_in_route)
                                        REFERENCES Intermediate_seaport_of_route (route_id, sequence_number)
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Departure_port_number_in_route INTEGER NOT NULL,
      FOREIGN KEY (Route_id, Departure_port_number_in_route)
                                        REFERENCES Intermediate_seaport_of_route (route_id, sequence_number)
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Check (Destination_port_number_in_route > Departure_port_number_in_route),
      Voyage_id INTEGER NOT NULL REFERENCES Voyage
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Client_id INTEGER NOT NULL REFERENCES Client
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Tonnage INTEGER CHECK (Tonnage >= 0),
      Price INTEGER CHECK (Price >= 0),
      IMO_number INTEGER NOT NULL REFERENCES Cargo_ship
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);
CREATE INDEX declaration_route_index ON Ticket (Route_id, Destination_port_number_in_route, Departure_port_number_in_route);







