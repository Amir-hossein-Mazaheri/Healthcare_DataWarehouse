import pyodbc
import re


def is_date(date_str):
    pattern = r'^(?:(?:(?:19|20)\d{2})-(?:(?:0[1-9]|1[0-2]))-(?:0[1-9]|1\d|2\d|3[01]))$'
    return re.match(pattern, date_str) is not None


def connect_to_sql_server():
    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=127.0.0.1;"
        "DATABASE=source;"
        "UID=sa;"
        "PWD=@Amir1990;"
        "TrustServerCertificate=yes;"
    )

    connection = pyodbc.connect(connection_string)

    return connection.cursor()


def produce_sql_and_insert_into(data: list[tuple[str, list[dict]]], database="source", schema="Health", callback=None):
    cursor = connect_to_sql_server()
    print("Connected to Sql Server...")

    for portion in data:
        for record in portion[1]:
            values = record.values()
            values_str = ''

            for i, val in enumerate(values):
                if isinstance(val, str):
                    if is_date(val):
                        values_str += f"CONVERT(DATE, '{val}', 120)"
                    else:
                        replaced_val = val.replace("'", "''")
                        values_str += f"N'{replaced_val}'"
                else:
                    values_str += str(val)

                if i != len(values) - 1:
                    values_str += ', '

            sql = f'insert into {database}.{schema}.{portion[0]} values ({values_str})'
            print(sql)
            cursor.execute(sql)
            cursor.commit()

    if callback is not None:
        callback(cursor)

    cursor.close()
