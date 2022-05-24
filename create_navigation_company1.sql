CREATE TABLE Capitan
(
    capitan_id                     INTEGER     NOT NULL PRIMARY KEY,
    Work_experience                            SMALLINT    NOT NULL CHECK (Work_experience >= 0),
    Full_name                             VARCHAR(50) NOT NULL,
    Passport_number                  CHAR(6)     NOT NULL,
    CHECK (Passport_number LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'),
    Passport_series                  CHAR(4)     NOT NULL,
    CHECK (Passport_series LIKE '[0-9][0-9][0-9][0-9]'),
    UNIQUE (Passport_series, Passport_number),
    Permission_to_ship_management BOOLEAN     NOT NULL
);

CREATE TABLE Ship_decommissioning_act
(
    Act_id    INTEGER NOT NULL PRIMARY KEY CHECK (Act_id >= 0),
    Decommissioning_date DATE    NOT NULL,
    CHECK (Decommissioning_date >= '1900-01-01' AND Decommissioning_date <= '2025-01-01')
);

CREATE TABLE Ship
(
    IMO_number   INTEGER     NOT NULL PRIMARY KEY,
    Name    VARCHAR(30),
    capitan_id INTEGER     NOT NULL REFERENCES Capitan
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    Ship_type   VARCHAR(20) NOT NULL,
    CHECK (Ship_type IN ('Accompanying_ship', 'Target_ship')),
    Release_date DATE,
    CHECK (Release_date >= '1900-01-01' AND Release_date <= '2025-01-01'),
    Maintenance_price_per_year INTEGER,
    CHECK(Maintenance_price_per_year >= 0),
    Status VARCHAR(30),
    CHECK (Status IN ('в рейсе', 'на ремонте', 'в доках компании', 'захвачен пиратами')),
    Act_id INTEGER NOT NULL CHECK (Act_id >= 0) REFERENCES Ship_decommissioning_act
                                                        ON DELETE RESTRICT
                                                        ON UPDATE CASCADE,
    Ship_class VARCHAR(20) NOT NULL
    CHECK (Ship_class IN ('Passenger_ship', 'Cargo_ship'))
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
    Seaport_id INTEGER NOT NULL PRIMARY KEY CHECK (Seaport_id >= 0),
    Name VARCHAR(50) NOT NULL,
    Country  VARCHAR(30),
    City VARCHAR(40),
    UNIQUE(Name, Country, City),
    Cost_of_stay INTEGER CHECK(Cost_of_stay >= 0),
    Shipping_cost INTEGER CHECK(Shipping_cost >= 0),
    Longitude DECIMAL(7,4) NOT NULL,
    CHECK (Longitude >= -180 AND Longitude <= 180),
    Latitude DECIMAL(6,4) NOT NULL,
    CHECK (Latitude >= -90 AND Latitude <= 90)
);

CREATE TABLE Маршрут
(
    Номер_маршрута INTEGER NOT NULL PRIMARY KEY,
    CHECK (Номер_маршрута >= 0),
    Код_порта_прибытия INTEGER NOT NULL REFERENCES Порт
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Код_порта_отправления INTEGER NOT NULL REFERENCES Порт
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE
);

CREATE TABLE Промежуточный_порт_маршрута
(
    Порядковый_номер INTEGER NOT NULL CHECK(Порядковый_номер >= 0),
    Номер_маршрута INTEGER NOT NULL REFERENCES Маршрут
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE,
    PRIMARY KEY (Порядковый_номер, Номер_маршрута),
    Код_порта INTEGER NOT NULL REFERENCES Порт
                                    ON DELETE RESTRICT
                                    ON UPDATE CASCADE
);

CREATE TABLE Рейс
(
    Номер_рейса INTEGER NOT NULL PRIMARY KEY,
    CHECK (Номер_рейса >= 0),
    Номер_маршрута  INTEGER NOT NULL REFERENCES Маршрут
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Дата_отправления DATE NOT NULL,
    CHECK(Дата_отправления >= '1900-01-01' AND Дата_отправления <= '2025-01-01'),
    Дата_прибытия DATE NOT NULL,
    CHECK(Дата_прибытия >= '1900-01-01' AND Дата_прибытия <= '2025-01-01'
          AND Дата_прибытия >= Дата_отправления),
    UNIQUE (Номер_маршрута, Дата_отправления, Дата_прибытия),
    Общее_расстояние INTEGER CHECK (Общее_расстояние >= 0)
);

CREATE TABLE Судно_назначенное_на_рейс
(
    Номер_IMO INTEGER NOT NULL REFERENCES Судно
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Номер_рейса INTEGER NOT NULL REFERENCES Рейс
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    PRIMARY KEY (Номер_IMO, Номер_рейса)
);

CREATE TABLE Класс_каюты
(
    Наименование_класса VARCHAR(20) NOT NULL PRIMARY KEY,
    CHECK (Наименование_класса IN ('эконом', 'бизнес', 'люкс')),
    Количество_мест INTEGER NOT NULL CHECK (Количество_мест >= 0),
    Базовая_стоимость_аренды INTEGER NOT NULL,
    CHECK (Базовая_стоимость_аренды >= 0)
);

CREATE TABLE Вместимость_пассажирского_судна
(
    Наименование_класса VARCHAR(20) NOT NULL REFERENCES Класс_каюты
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    Номер_IMO   INTEGER     NOT NULL REFERENCES Пассажирское_судно
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    PRIMARY KEY (Наименование_класса, Номер_IMO),
    Количество_кают INTEGER NOT NULL CHECK(Количество_кают >= 0)
);

CREATE TABLE Билет
(
    Номер_билета INTEGER NOT NULL PRIMARY KEY,
    CHECK (Номер_билета >= 0),
    Номер_рейса INTEGER NOT NULL REFERENCES Рейс
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Наименование_класса VARCHAR(20) NOT NULL REFERENCES Класс_каюты
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    Код_порта_прибытия INTEGER NOT NULL REFERENCES Порт
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
    Код_порта_отправления INTEGER NOT NULL REFERENCES Порт
                                            ON DELETE RESTRICT
                                            ON UPDATE CASCADE,
    Стоимость INTEGER NOT NULL CHECK (Стоимость >= 0), /*как ослаться на базовую стоимость каюты в default*/
    Номер_IMO INTEGER NOT NULL REFERENCES Пассажирское_судно
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);

CREATE TABLE Клиент
(
    id_клиента INTEGER NOT NULL PRIMARY KEY CHECK(id_клиента >= 0),
    ФИО VARCHAR(50) NOT NULL UNIQUE,
    Номер_паспорта                  CHAR(6)     NOT NULL,
    CHECK (Номер_паспорта LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'),
    Серия_паспорта                  CHAR(4)     NOT NULL,
    CHECK (Серия_паспорта LIKE '[0-9][0-9][0-9][0-9]'),
    UNIQUE (Серия_паспорта, Номер_паспорта),
    Внутренний_счёт VARCHAR(30) NOT NULL,
    Фото TEXT NOT NULL UNIQUE
);

CREATE TABLE Факт_покупки_билета
(
    id_клиента INTEGER NOT NULL REFERENCES Клиент
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    Номер_билета INTEGER NOT NULL REFERENCES Билет
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE,
    PRIMARY KEY (id_клиента, Номер_билета)
);

CREATE TABLE Тип_груза
(
    Название_типа VARCHAR(30) NOT NULL PRIMARY KEY,
    Стоимость_перевозки_1_тонны INTEGER NOT NULL,
    CHECK (Стоимость_перевозки_1_тонны >= 0),
    Перечень_товаров_в_группе TEXT NOT NULL
);

CREATE TABLE Судовая_декларация
(
      Код_судовой_декларации INTEGER NOT NULL PRIMARY KEY,
      Название_типа VARCHAR(30) NOT NULL REFERENCES Тип_груза
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Код_порта_прибытия INTEGER NOT NULL REFERENCES Порт
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Код_порта_отправления INTEGER NOT NULL REFERENCES Порт
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Номер_рейса INTEGER NOT NULL REFERENCES Рейс
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      id_клиента INTEGER NOT NULL REFERENCES Клиент
                                        ON DELETE RESTRICT
                                        ON UPDATE CASCADE,
      Тоннаж INTEGER CHECK (Тоннаж >= 0),
      Стоимость INTEGER CHECK (Стоимость >= 0),
      Номер_IMO INTEGER NOT NULL REFERENCES Грузовое_судно
                                ON DELETE RESTRICT
                                ON UPDATE CASCADE
);










