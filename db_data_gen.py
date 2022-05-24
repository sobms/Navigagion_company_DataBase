import psycopg2
from bs4 import BeautifulSoup
import requests
import os
import lxml
import re
import numpy as np
from russian_names import RussianNames
import random
import rstr
from faker import Faker
from datetime import timedelta

class DatabaseGenerator():
    def __init__(self):
        try:
            # Подключение к существующей базе данных
            self.connection = psycopg2.connect(dbname="NavigationCompany", user="misha21", password="3891", host="localhost", port="5433")
            # Курсор для выполнения операций с базой данных
            self.cursor = self.connection.cursor()
            print("Информация о сервере PostgreSQL")
            print(self.connection.get_dsn_parameters(), "\n")
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)
    def close_connection(self):
        self.cursor.close()
        self.connection.close()
        print("Соединение с PostgreSQL закрыто")

    def seaport_gen(self):
        url = 'https://ru.wikipedia.org/wiki/Список_морских_портов_России'
        rs = requests.session()
        page = rs.get(url, auth=('user', 'pass'))
        soup = BeautifulSoup(page.text, 'lxml')
        tab = soup.find_all('table', class_='wikitable wide')[0]
        rows = tab.find_all('tr')
        port_names = [re.findall("[ а-яА-Яё-]+", row.find_all('td')[0].text)[0] for row in rows[3:]]
        port_names.remove('Чёрное море') #!!!!
        coords_width = []
        coords_longitude = []
        for row in rows[3:]:
            try:
                coefs = re.split('°|′|″', re.findall("[0-9°′″]+", row.find_all('td')[2].text)[0])
                coords_width.append(1*int(coefs[0]) + 1/60*int(coefs[1]) + 1/3600*int(coefs[2]))
                coefs = re.split('°|′|″', re.findall("[0-9°′″]+", row.find_all('td')[2].text)[1])
                coords_longitude.append(1*int(coefs[0]) + 1/60*int(coefs[1]) + 1/3600*int(coefs[2]))
            except (Exception, psycopg2.DatabaseError) as error:
                pass
        shipping_cost = [np.random.randint(10000, 20000) for i in range(len(port_names))]
        Cost_of_stay = [np.random.randint(5000, 15000) for i in range(len(port_names))]
        city = ['Азов', 'Ейск', 'Ростов-на-Дону', 'Таганрог', 'Темрюк', 'Краснодар', 'Анапа',
                'Геленджик', 'Новороссийск', 'Сочи', 'село Волна', 'Туапсе', 'Керчь', 'Севастополь',
                'Феодосия', 'Ялта', 'Евпатория']
        for i in range(0, len(port_names)):
            try:
                self.cursor.execute('INSERT INTO seaport(name, country, city, cost_of_stay_per_day, shipping_cost, longitude, latitude) \
                                VALUES (%s, %s, %s, %s, %s, %s, %s)', (port_names[i], 'РФ', city[i], Cost_of_stay[i],
                                shipping_cost[i], coords_longitude[i], coords_width[i]))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()
        return len(port_names)

    def capitan_gen(self, num):
        work_experience = np.random.randint(1, 15, size=num)
        full_names = RussianNames(count=num, gender=0.95).get_batch()
        passport_numbers = np.random.randint(100000, 999999, size=num)
        passport_series = np.random.randint(1000, 9999, size=num)
        permissions = [random.choices([False, True], weights=[10, 90])[0] for _ in range(num)]
        for i in range(0, num):
            try:
                self.cursor.execute('INSERT INTO capitan(Work_experience, Full_name, Passport_number, Passport_series, \
                                Permission_to_ship_management) VALUES (%s, %s, %s, %s, %s)', (int(work_experience[i]), full_names[i],
                                str(passport_numbers[i]), str(passport_series[i]), permissions[i]))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()

    def clients_gen(self, num):
        full_names = RussianNames(count=num, gender=0.5).get_batch()
        passport_numbers = np.random.randint(100000, 999999, size=num)
        passport_series = np.random.randint(1000, 9999, size=num)
        internal_accounts = [rstr.xeger('[a-zA-Z0-9]{15}') for _ in range(num)]
        photos = [rstr.xeger('https://drive\.google\.com/drive/folders/[a-zA-Z0-9_#-]{7}') for _ in range(num)]
        for i in range(0, num):
            try:
                self.cursor.execute('INSERT INTO client(Full_name, Passport_number, Passport_series, \
                                Internal_account, Photo) VALUES (%s, %s, %s, %s, %s)', (full_names[i],
                                str(passport_numbers[i]), str(passport_series[i]), str(internal_accounts[i]), str(photos[i])))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()
    def insert_stateroom_classes(self):
        try:
            self.cursor.execute("insert into stateroom_class values (%s, 6, 30000), \
                                (%s, 2, 40000), \
                                (%s, 3, 27000)", ('эконом','люкс','бизнес'))
            self.connection.commit()
        except (Exception, psycopg2.DatabaseError) as error:
            self.connection.rollback()

    def insert_cargo_types(self):
        try:
            self.cursor.execute("""insert into cargo_type values (%(t1)s, 5000, %(l1)s), \
                                (%(t2)s, 8000, %(l2)s), \
                                (%(t3)s, 7000, %(l3)s), \
                                (%(t4)s, 4000, %(l4)s), \
                                (%(t5)s, 10000, %(l5)s), \
                                (%(t6)s, 9000, %(l6)s), \
                                (%(t7)s, 5000, %(l7)s)""",
            {'t1':'уголь', 't2':'нефть', 't3':'стройматериалы',
            't4':'древесина', 't5':'приборы и оборудование', 't6':'боевая техника','t7':'золото',
            'l1':'каменный уголь, бурый уголь','l2':'нефть','l3':'ДСП, ДВП, кирпич, пластиковые панели, стекло, полимерные трубы...',
             'l4':'берёза, сосна, дуб','l5':'электроприборы, станки','l6':'бмп, танки, бтр, артиллеррия','l7':'золото'})
            self.connection.commit()
        except (Exception, psycopg2.DatabaseError) as error:
            self.connection.rollback()

    def decommissioning_acts_gen(self, num):
        fake = Faker()
        dates = [fake.date_between(start_date='-12y', end_date='now') for _ in range(num)]
        print(str(dates[0]))
        for i in range(0, num):
            try:
                self.cursor.execute("""INSERT INTO Ship_decommissioning_act(Decommissioning_date) \
                VALUES (%(date)s);""", {'date':dates[i]})
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()

    def ship_gen(self, num, act_ids_len, capitans_ids_len):
        imo_number = np.random.randint(100, 999999, size=num)
        p_imo_numbers = []
        c_imo_umbers = []
        url = 'https://rgavmf.ru/books/boevaya-letopis-russkogo-flota/ukazatel-nazvaniy-korabley'
        rs = requests.session()
        page = rs.get(url, auth=('user', 'pass'))
        soup = BeautifulSoup(page.text, 'lxml')
        data = soup.find_all('div', class_='region region-content well')[0]
        names_stuff = re.findall('«.*»', data.text)
        names = [np.random.choice(names_stuff).strip('«»')[:56] + rstr.xeger('[0-9]{1,2}') for _ in range(num)]
        capitans_id = np.random.choice(range(capitans_ids_len), num)
        ship_types = np.random.choice(['Accompanying_ship', 'Target_ship'], num, p=[0.3,0.7])
        fake = Faker()
        release_dates = [fake.date_between(start_date='-12y', end_date='now') for _ in range(num)]
        ship_classes = np.random.choice(['Passenger_ship', 'Cargo_ship'], num, p=[0.55,0.45])
        statuses = np.random.choice(['в рейсе', 'на ремонте', 'в доках компании', 'захвачен пиратами'], num, p=[0.7,0.1,0.15,0.05])
        maintenance_prices_per_year = np.random.randint(50000, 2000000, size=num)
        decommissioned_ships = list(np.unique(np.random.choice(imo_number, act_ids_len)))
        dict_of_decommissioned_ships = dict(zip(decommissioned_ships, list(range(1, len(decommissioned_ships)+1))))
        act_ids = [None if imo not in decommissioned_ships else dict_of_decommissioned_ships[imo] for imo in imo_number]
        tonnages = np.random.choice([1,2,4,5,8,10,15,20,25,30,40,50,60,70,80,100,150,200,250,500,600,700,800,900,1000], sum(ship_classes == 'Cargo_ship'))
        c_s = 0
        for i in range(0, num):
            try:
                self.cursor.execute("""INSERT INTO Ship \
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""", (int(imo_number[i]), str(names[i]), int(capitans_id[i]),
                str(ship_types[i]), release_dates[i], int(maintenance_prices_per_year[i]), str(statuses[i]), act_ids[i], str(ship_classes[i])))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()
                continue

            if str(ship_classes[i]) == 'Cargo_ship':
               try:
                  c_imo_umbers.append(imo_number[i])
                  self.cursor.execute('INSERT INTO Cargo_ship \
                                       VALUES (%s, %s)', (int(imo_number[i]), int(tonnages[c_s])))
                  c_s += 1
               except (Exception, psycopg2.DatabaseError) as error:
                  self.connection.rollback()
            elif str(ship_classes[i]) == 'Passenger_ship':
               try:
                  p_imo_numbers.append(imo_number[i])
                  self.cursor.execute("""INSERT INTO Passenger_ship \
                                        VALUES (%(imo)s)""", {'imo':int(imo_number[i])})
               except (Exception, psycopg2.DatabaseError) as error:
                  self.connection.rollback()
            self.connection.commit()

        return c_imo_umbers, p_imo_numbers, imo_number

    def routes_gen(self, num, max_port_id):
        destination_seaport_ids = np.random.randint(1, max_port_id, size=num)
        departure_seaport_ids = np.random.randint(1, max_port_id, size=num)
        for i in range(0, num):
            try:
                self.cursor.execute('INSERT INTO route(Destination_seaport_id, Departure_seaport_id) \
                VALUES (%s, %s)', (int(destination_seaport_ids[i]), int(departure_seaport_ids[i])))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()

    def intermediate_seaport_of_route(self, routes_num, max_port_id):
        intermediate_seaports_for_routes = []
        for i in range(routes_num):
            while True:
                route_size = np.random.randint(2, 10)
                ports = np.random.randint(1, max_port_id, size=route_size).tolist()
                i = 1
                while i < len(ports):
                    if ports[i] == ports[i-1]:
                        ports.pop(i)
                    i+=1
                if len(ports) > 1:
                    break
            intermediate_seaports_for_routes.append(ports)
        for i in range(0, routes_num):
            for j in range(len(intermediate_seaports_for_routes[i])):
                try:
                    self.cursor.execute('INSERT INTO Intermediate_seaport_of_route \
                    VALUES (%s, %s, %s)', (j, i+1, intermediate_seaports_for_routes[i][j-1]))
                    self.connection.commit()
                except (Exception, psycopg2.DatabaseError) as error:
                    self.connection.rollback()
        return dict(zip(range(1, routes_num+1), intermediate_seaports_for_routes))

    def voyage_gen(self, num, routes_num):
        voyage_ids = np.random.randint(100000, 999999, size=num)
        route_ids = np.random.randint(1, routes_num, size=num)
        inserted_voyage_ids = []
        inserted_route_ids = []
        fake = Faker()
        departure_date = [fake.date_between(start_date='-12y', end_date='now') for _ in range(num)]
        arrival_date = [i + timedelta(days=np.random.randint(0,2)) for i in departure_date]
        total_distances = np.random.randint(100, 2400, size=num)
        for i in range(0, num):
            try:
                self.cursor.execute('INSERT INTO voyage VALUES (%s, %s, %s, %s, %s)',
                (int(voyage_ids[i]), int(route_ids[i]), departure_date[i], arrival_date[i], int(total_distances[i])))
                self.connection.commit()
                inserted_voyage_ids.append(int(voyage_ids[i]))
                inserted_route_ids.append(int(route_ids[i]))
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()
        return inserted_voyage_ids, inserted_route_ids

    def ship_assigned_to_voyage_gen(self, voyage_ids, ship_imo_numbers):
        ship_assigned_to_voyage_dict = {}
        for id in voyage_ids:
            for i in range(np.random.randint(1,4)): # количество кораблей в рейсе
                try:
                    ship_id = np.random.choice(ship_imo_numbers)
                    self.cursor.execute('INSERT INTO Ship_assigned_to_voyage VALUES (%s, %s)', (int(ship_id), int(id)))
                    self.connection.commit()
                    if id in ship_assigned_to_voyage_dict.keys():
                        ship_assigned_to_voyage_dict[id].append(ship_id)
                    else:
                        ship_assigned_to_voyage_dict[id] = []
                        ship_assigned_to_voyage_dict[id].append(ship_id)
                except (Exception, psycopg2.DatabaseError) as error:
                    self.connection.rollback()
        return ship_assigned_to_voyage_dict

    def tickets_gen(self, num, voyage_ids, route_ids, ship_assigned_to_voyage_dict, dict_intermediate_ports):
        random_indexes = np.random.randint(1,len(voyage_ids), size=num)
        tickets_voyage_ids = [voyage_ids[i] for i in random_indexes]
        tickets_route_ids = [route_ids[i] for i in random_indexes]
        classes_name = np.random.choice(['эконом', 'бизнес', 'люкс'], num, p=[0.5,0.3,0.2])
        price = np.random.randint(2, 5, size=num)
        #price = list(map(lambda x: round(x, -2),price))
        ship_imo_numbers = []
        for i in random_indexes:
            try:
                ship_imo_numbers.append(np.random.choice(ship_assigned_to_voyage_dict[voyage_ids[i]]))
            except:
                ship_imo_numbers.append(None)
        dep_port_nums = [np.random.randint(1, len(dict_intermediate_ports[tickets_route_ids[i]]))
                        for i in random_indexes]
        dest_port_nums = []
        k = 0
        for i in random_indexes:
            dest_port_nums.append(np.random.randint(dep_port_nums[k], len(dict_intermediate_ports[tickets_route_ids[i]])))
            k+=1
        tickets_added = []
        k = 1
        for i in random_indexes:
            try:
               self.cursor.execute('INSERT INTO Ticket(Voyage_id, Class_name, Route_id, Destination_port_number_in_route,\
                                   Departure_port_number_in_route, Price, IMO_number) VALUES (%s, %s, %s, %s, %s, %s, %s)',
                                   (int(tickets_voyage_ids[i]), str(classes_name[i]), int(tickets_route_ids[i]),
                                    int(dest_port_nums[i]), int(dep_port_nums[i]), int(price[i]), int(ship_imo_numbers[i])))
               self.connection.commit()
               tickets_added.append(k)
            except (Exception, psycopg2.DatabaseError) as error:
               self.connection.rollback()
            k += 1
        return tickets_added

    def fact_of_tickets_purchase_gen(self, tickets_numbers, clients_num):
        fact_of_tickets_purchase = {}
        was_ticket_buy = np.random.choice([True, False], len(tickets_numbers), p=[0.3,0.7])
        for i in range(0, len(tickets_numbers)):
            if was_ticket_buy[i]:
                fact_of_tickets_purchase[tickets_numbers[i]] = np.random.choice(clients_num)
        for k in fact_of_tickets_purchase.keys():
            try:
                self.cursor.execute('INSERT INTO Fact_of_ticket_purchase VALUES (%s, %s)',
                                    (int(fact_of_tickets_purchase[k]), k))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()

    def passenger_ship_capacity_gen(self, imo_numbers):
        luxe_staterooms = np.random.randint(0, 20, size=len(imo_numbers))
        econom_staterooms = np.random.randint(5, 60, size=len(imo_numbers))
        bisness_staterooms = np.random.randint(0, 30, size=len(imo_numbers))
        for i in range(0, len(imo_numbers)):
            try:
                self.cursor.execute('INSERT INTO Passenger_ship_capacity VALUES (%s, %s, %s)',
                                    ('люкс', int(imo_numbers[i]), int(luxe_staterooms[i])))
                self.cursor.execute('INSERT INTO Passenger_ship_capacity VALUES (%s, %s, %s)',
                                    ('эконом', int(imo_numbers[i]), int(econom_staterooms[i])))
                self.cursor.execute('INSERT INTO Passenger_ship_capacity VALUES (%s, %s, %s)',
                                    ('бизнес', int(imo_numbers[i]), int(bisness_staterooms[i])))
                self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
                self.connection.rollback()

    def ship_declaration_gen(self, num, clients_count, voyage_ids, route_ids, ship_assigned_to_voyage_dict, dict_intermediate_ports):
        clients = np.random.randint(1, clients_count, size=num)
        type_names = np.random.choice(['уголь','нефть','стройматериалы',
        'древесина','приборы и оборудование','боевая техника','золото'], size=num)
        random_indexes = np.random.randint(1, len(voyage_ids), size=num)
        declarations_voyage_ids = [voyage_ids[i] for i in random_indexes]
        declarations_route_ids = [route_ids[i] for i in random_indexes]
        ship_imo_numbers = []
        for i in random_indexes:
            try:
                ship_imo_numbers.append(np.random.choice(ship_assigned_to_voyage_dict[voyage_ids[i]]))
            except:
                ship_imo_numbers.append(None)
        tonnage = np.random.randint(1, 50, size=num)
        price = (np.random.randint(5000, 40000, size=num)*tonnage)
        price = list(map(lambda x: round(x, -2), price))
        dep_port_nums = [np.random.randint(1, len(dict_intermediate_ports[declarations_route_ids[i]]))
                         for i in random_indexes]
        dest_port_nums = []
        k = 0
        for i in random_indexes:
            dest_port_nums.append(
                np.random.randint(dep_port_nums[k], len(dict_intermediate_ports[declarations_route_ids[i]])))
            k += 1
        for i in range(0,num):
            try:
               self.cursor.execute('INSERT INTO ship_declaration(Type_name, Route_id, Destination_port_number_in_route, \
                                   Departure_port_number_in_route, Voyage_id, Client_id, Tonnage, Price, IMO_number) \
                                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)',
                                   (str(type_names[i]), int(declarations_route_ids[i]), int(dest_port_nums[i]), int(dep_port_nums[i]),
                                    int(declarations_voyage_ids[i]), int(clients[i]), int(tonnage[i]), int(price[i]), int(ship_imo_numbers[i])))
               self.connection.commit()
            except (Exception, psycopg2.DatabaseError) as error:
               self.connection.rollback()

if __name__ == '__main__':
    gen = DatabaseGenerator()
    ports_len = gen.seaport_gen()
    capitans = 80000
    gen.capitan_gen(capitans)
    clients = 140000
    #gen.clients_gen(clients)
    acts = 5000
    gen.decommissioning_acts_gen(acts)
    ships = 120000
    c_imo_umbers, p_imo_numbers, ship_imo_numbers = gen.ship_gen(ships, acts, capitans)
    routes = 350
    gen.routes_gen(routes, ports_len)
    intermediate_ports_dict = gen.intermediate_seaport_of_route(routes, ports_len)
    voyages = 140000
    voyages_ids, routes_ids = gen.voyage_gen(voyages, routes)
    ship_assigned_to_voyage_dict = gen.ship_assigned_to_voyage_gen(voyages_ids, ship_imo_numbers)
    gen.insert_stateroom_classes()
    gen.insert_cargo_types()
    tickets = 800000
    tickets_numbers = gen.tickets_gen(tickets, voyages_ids, routes_ids, ship_assigned_to_voyage_dict, intermediate_ports_dict)
    gen.fact_of_tickets_purchase_gen(tickets_numbers, clients)
    gen.passenger_ship_capacity_gen(p_imo_numbers)
    gen.ship_declaration_gen(900000, clients, voyages_ids, routes_ids, ship_assigned_to_voyage_dict, intermediate_ports_dict)
    gen.close_connection()