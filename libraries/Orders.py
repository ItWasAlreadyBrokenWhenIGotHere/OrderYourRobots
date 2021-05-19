#!/usr/bin/env python3
import csv
from csv import DictReader


class Orders:
    # Read content of Order.csv and return it as list (table) to be used in RobotFramework
    def get_orders(self, csv_file):

        with open(csv_file, 'r') as file:
            csv_orders = DictReader(file)

            orders = []
            for row in csv_orders:
                # print(row)
                order = {
                    "order_number": row["Order number"],
                    "head": row["Head"],
                    "body": row["Body"],
                    "legs": row["Legs"],
                    "address": row["Address"]
                }
                orders.append(order)

            return orders
