import datetime
import calendar
import jdatetime
from common import produce_sql_and_insert_into


def get_days_in_month(year, month):
    days_in_month = calendar.monthrange(year, month)[1]
    return days_in_month


def get_persian_day_number_of_year(month: int, day: int):
    number = day

    for i in range(1, month):
        if i <= 6:
            number += 31
        else:
            number += 30

    return number


def get_quarter(month: int):
    quarter = (month - 1) // 3 + 1
    return quarter


def time_generator(start_year: int, end_year: int):
    persian_weekday_names = {
        'Saturday': 'شنبه',
        'Sunday': 'یک‌شنبه',
        'Monday': 'دوشنبه',
        'Tuesday': 'سه‌شنبه',
        'Wednesday': 'چهارشنبه',
        'Thursday': 'پنج‌شنبه',
        'Friday': 'جمعه'
    }

    time_dimension = []

    for year in range(start_year, end_year + 1):
        for month in range(1, 13):
            days_count = get_days_in_month(year, month)

            for day in range(1, days_count + 1):
                time_key = datetime.datetime(year, month, day)
                persian_date = jdatetime.date.fromgregorian(date=time_key)

                time = {
                    "time_key": f'{time_key.year}-{time_key.month}-{time_key.day}',
                    "full_date_alternate_key": f'{month}/{day}/{year}',
                    "persian_full_date_alternate_key": f'{persian_date.year}/{persian_date.month}/{persian_date.day}',
                    "day_number_of_week": time_key.weekday(),
                    "persian_day_number_of_week": persian_date.weekday(),
                    "day_name_of_week": time_key.strftime("%A"),
                    "persian_day_name_of_week": persian_weekday_names[time_key.strftime("%A")],
                    "day_number_of_month": month,
                    "persian_day_number_of_month": persian_date.day,
                    "day_number_of_year": time_key.timetuple().tm_yday,
                    "persian_day_number_of_year": get_persian_day_number_of_year(persian_date.month, persian_date.day),
                    "week_number_of_year": time_key.isocalendar()[1],
                    "persian_week_number_of_year": persian_date.isocalendar()[1],
                    "month_name": time_key.strftime('%B'),
                    "persian_month_name": persian_date.strftime('%B'),
                    "month_number_of_year": month,
                    "persian_month_number_of_year": persian_date.month,
                    "calendar_quarter": get_quarter(month),
                    "persian_calendar_quarter": get_quarter(persian_date.month),
                    "calendar_year": year,
                    "persian_calendar_year": persian_date.year,
                }

                time_dimension.append(time)

    return time_dimension


def callback(time_dimension):
    def closure(cursor):
        value_ranges = ""

        for i, time in enumerate(time_dimension):
            time_key = time["time_key"]
            value_ranges += f"'{time_key}'"

            if i != len(time_dimension) - 1:
                value_ranges += ", "

        sql_str = f"use data_warehouse; create partition function DayPartition (date) as range left for values ({value_ranges})"

        print(sql_str)
        cursor.execute(sql_str)
        cursor.commit()

    return closure


if __name__ == '__main__':
    t = time_generator(2020, 2050)
    print(len(t))
    produce_sql_and_insert_into([("Dim_Time", t)], "data_warehouse", "Warehouse", callback(t))
