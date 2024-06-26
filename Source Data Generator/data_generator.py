import json
from random import randint, shuffle
from common import produce_sql_and_insert_into


# Each table has its own generator function
# First tables that are most depended on are generated

# I used this function to check firstnames and lastnames of patients which is in the json file
# the reason is I got those names from ChatGPT and wasn't sure about duplicates
def get_duplicates(names):
    visited = []
    duplicates = []

    for name in names:
        if name in visited:
            duplicates.append(name)

        visited.append(name)

    return duplicates


reserved_national_code = []


# This function just put 10 random numbers together and don't check for uniqueness
def generate_national_code():
    return str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(
        randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9))


# This function uses random national code but check weather It's reserved or not and tries as many times to pass
def generate_unique_national_code():
    while True:
        national_code = generate_national_code()

        if national_code in reserved_national_code:
            continue

        reserved_national_code.append(national_code)

        return national_code


def get_random_date(start_year: int, end_year: int):
    month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    dob_year = randint(start_year, end_year)
    month = randint(1, 12)
    day = randint(1, month_days[month - 1])

    return str(dob_year) + '-' + ('0' + str(month) if month < 10 else str(month)) + '-' + (
        '0' + str(day) if day < 10 else str(day))


def get_departments():
    with open('departments.json', 'r') as file:
        departments: list[str] = json.load(file)

        return [{"department_id": i + 1, "department_name": item} for i, item in enumerate(departments)]


def phone_number_generator():
    return '9' + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(
        randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9))


# This function generates 400 doctors that are above average for a healthcare
def generate_doctors(departments: list[dict]):
    # Each item in specialization is related to the corresponding department in order
    with open('specializations.json', 'r') as file:
        specializations: list[list[str]] = json.load(file)

    with open('doctors_names.json', 'r') as file:
        firstnames_gender, lastnames = json.load(file).values()

    doctors = []
    index = 1

    for firstname_gender in firstnames_gender:
        for lastname in lastnames:
            firstname, gender = firstname_gender
            department_index = randint(0, len(departments) - 1)
            specialization_index = randint(0, 4)

            doctor = {
                "doctor_id": index,
                "national_code": generate_unique_national_code(),
                "firstname": firstname,
                "lastname": lastname,
                "gender": gender,
                "phone": phone_number_generator(),
                "specializations": specializations[department_index][specialization_index],
                "department_id": departments[department_index]["department_id"],
            }

            doctors.append(doctor)

            index += 1

    shuffle(doctors)

    return doctors


# This function generates 10,000 patients, and also you set round to be more than 1
# i.e., to generate 1 million patients, you should set round to 100
# which produces duplicate firstname and lastname combos, but with different national_code
# keep in mind as the round grows, the process takes much longer due to unique national code
def generate_patients(rounds=1):
    with open('patient_names.json', 'r') as file:
        firstnames_gender, lastnames = json.load(file).values()

        # You can feed you your own data to the script and uncomment this part to check
        # for duplicates firstnames and lastnames
        # pprint(get_duplicates([item[0] for item in firstnames_gender]))
        # print('-' * 100)
        # pprint(get_duplicates(lastnames))

    patients = []
    index = 1

    for _ in range(rounds):
        for firstname_gender in firstnames_gender:
            for lastname in lastnames:
                firstname, gender = firstname_gender

                patient = {
                    "patient_id": index,
                    "national_code": generate_unique_national_code(),
                    "firstname": firstname,
                    "lastname": lastname,
                    "dob": get_random_date(1995, 2010),
                    "gender": gender,
                    "phone": phone_number_generator(),
                }

                patients.append(patient)

                index += 1

    shuffle(patients)

    return patients


def weighted_rand_selector(a: tuple[any, int], b: tuple[any, int]):
    probability = randint(1, 100)

    if probability <= (a[1] if a[1] < b[1] else b[1]):
        return a[0]
    else:
        return b[0]


def calculate_visit_cost(department_id, doctor_id, is_checkup):
    departments_cost_effect = [2, 7, 4, 3, 1, 6, 5]
    unit = 5000

    cost = departments_cost_effect[department_id - 1] * doctor_id * unit

    # Checkup visits cost half
    return cost / 2 if is_checkup else cost


# Visit per patient means that how many visits should be generated for each patient
# default is 100 to produce 1 million visits, but you can increase it
def generate_visits(doctors: list[dict], patients: list[dict], visit_per_patient=100):
    lorem_ipsum = ("Lorem ipsum dolor sit amet, consectetur adipiscing elit, "
                   "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
                   "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris "
                   "nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in "
                   "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
                   "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia "
                   "deserunt mollit anim id est laborum.")
    index = 1
    visits = []

    for patient in patients:
        for _ in range(visit_per_patient):
            doctor_index = randint(0, len(doctors) - 1)
            doctor_id = doctors[doctor_index]["doctor_id"]
            department_id = doctors[doctor_index]["department_id"]
            # this line make the 10% of the visits checkup
            is_checkup = weighted_rand_selector((1, 10), (0, 90))

            visit = {
                "visit_id": index,
                "patient_id": patient["patient_id"],
                "doctor_id": doctor_id,
                "visit_date": get_random_date(2021, 2023),
                "diagnosis": lorem_ipsum[:randint(50, len(lorem_ipsum) - 1)],
                "visit_cost": calculate_visit_cost(department_id, doctor_id, is_checkup),
                "is_check_up": is_checkup
            }

            visits.append(visit)

            index += 1

    return visits


def calculate_treatment_cost(treatment_effect: int, department_effect: int, index_effect: int):
    max_treatment_effect = 10
    max_department_effect = 7
    max_index_effect = 15

    # You can calculate the GDC for the 10, 7, and 15 dynamically if you need
    gdc = 5 * 2 * 7 * 3

    # Because the max effect are not the same I normalize them to compare them
    normalized_treatment_effect = treatment_effect * (gdc / max_treatment_effect)
    normalized_department_effect = department_effect * (gdc / max_department_effect)
    normalized_index_effect = index_effect * (gdc / max_index_effect)

    treatment_effect_weight = 6
    department_effect_weight = 4
    index_effect_weight = 1

    unit = 1000000

    return round(((normalized_treatment_effect * treatment_effect_weight * unit) + (
            normalized_department_effect * department_effect_weight * unit) + (
                          normalized_index_effect * index_effect_weight * unit)) / gdc, 2)


# In the treatment json file, each treatment type is associated with a number between 1 and 10
# to show some kind of effect on the cost.
# So to calculate the cost of the treatment, the most important factor is
# treatment type then department and the least effective is the treatment index
def generate_treatments(visits: list[dict], departments: list[dict]):
    with open('treatments.json', 'r') as file:
        treatment_types, treatment_descriptions = json.load(file).values()

    index = 1
    treatments = []
    departments_cost_effect = [2, 7, 4, 3, 1, 6, 5]

    for visit in visits:
        if visit["is_check_up"]:
            continue

        department_index = randint(0, len(departments) - 1)
        treatment_index = randint(0, len(treatment_descriptions[department_index]) - 1)

        treatment_description, treatment_type = treatment_descriptions[department_index][treatment_index]
        treatment_cost = calculate_treatment_cost(treatment_types[treatment_type][1],
                                                  departments_cost_effect[department_index], treatment_index)

        treatment = {
            "treatment_id": index,
            "visit_id": visit["visit_id"],
            "treatment_type": treatment_types[treatment_type][0],
            "treatment_description": treatment_description,
            "treatment_cost": treatment_cost,
            "department_id": departments[department_index]["department_id"],
        }

        treatments.append(treatment)

        index += 1

    return treatments


def find_index(lst, condition):
    return next((i for i, x in enumerate(lst) if condition(x)), -1)


def find(lst, condition, default=None):
    item = next((x for x in lst if condition(x)), None)

    if item is None:
        return default

    return item


def calculate_medication_cost(medication_effect, frequency, frequency_unit, duration):
    hour_in_minute = 60
    day_in_minute = 1 * 24 * hour_in_minute
    week_in_minute = 7 * day_in_minute
    month_in_minute = 30 * week_in_minute

    duration_in_minute = duration * day_in_minute

    frequency_in_minute = frequency

    if frequency_unit == "hour":
        frequency_in_minute = hour_in_minute * frequency
    elif frequency_unit == "day":
        frequency_in_minute = day_in_minute * frequency
    elif frequency_unit == "week":
        frequency_in_minute = week_in_minute * frequency
    elif frequency_unit == "month":
        frequency_in_minute = month_in_minute * frequency

    cycles = duration_in_minute / frequency_in_minute
    unit = 10000

    return round(medication_effect * cycles * unit, 2)


def generate_medications(treatments: list[dict], visits: list[dict]):
    with open('treatments.json', 'r') as file:
        treatment_types, treatment_descriptions = json.load(file).values()

    with open('medications.json', 'r') as file:
        medications_cost, medication_names = json.load(file).values()

    index = 1
    frequency_units = ('minute', 'hour', 'day', 'week', 'month')
    medications = []

    for treatment in treatments:
        department_index = treatment["department_id"] - 1
        treatment_description_index = find_index(treatment_descriptions[department_index],
                                                 lambda t: t[0] == treatment["treatment_description"])

        # The data I supplied always makes the range from 0 to 5,
        # but if you add or remove, this generator still works flawlessly
        department_treatment_medication = medication_names[department_index][treatment_description_index]

        # Some treatments don't have any medication so no medication is generated
        if department_treatment_medication is None:
            continue

        medication_index = randint(0, len(department_treatment_medication) - 1)
        medication_name = department_treatment_medication[medication_index]

        frequency_unit = frequency_units[randint(0, len(frequency_units) - 1)]
        frequency = randint(30, 480) if frequency_unit == 'minute' else randint(1, 12)

        duration = randint(1, 30)

        if frequency_unit != 'minute':
            duration = randint(1 + frequency, 30 * frequency)

        medication = {
            "medication_id": index,
            "visit_id": treatment["visit_id"],
            "medication_name": medication_name,
            "dosage": randint(30, 1000),  # milli gram
            "frequency": frequency,
            "frequency_unit": frequency_unit,
            "medication_cost": calculate_medication_cost(
                find(medications_cost, lambda cost: cost[0] == medication_name)[1],
                frequency, frequency_unit, duration),
            "prescription_date": visits[treatment["visit_id"] - 1]["visit_date"],
            "duration": duration,
        }

        medications.append(medication)

        index += 1

    return medications


def generate_billing(visits: list[dict], treatments: list[dict], medications: list[dict]):
    index = 1
    treatment_index = 0
    medication_index = 0
    billings = []

    for visit in visits:
        insurance_coverage_percentage = randint(10, 30) / 100
        tax_percentage = randint(15, 30) / 100

        treatment_cost = 0
        medication_cost = 0

        if treatments[treatment_index]["visit_id"] == visit["visit_id"]:
            treatment_cost = treatments[treatment_index]["treatment_cost"]
            treatment_index += 1

        if medications[medication_index]["visit_id"] == visit["visit_id"]:
            medication_cost = medications[medication_index]["medication_cost"]
            medication_index += 1

        total_amount_without_tax = visit["visit_cost"] + treatment_cost + medication_cost
        tax_amount = tax_percentage * total_amount_without_tax
        total_amount = total_amount_without_tax + tax_amount

        insurance_coverage = total_amount_without_tax * insurance_coverage_percentage
        paid_amount = total_amount - insurance_coverage

        billing = {
            "billing_id": index,
            "visit_id": visit["visit_id"],
            "total_amount": total_amount,
            "paid_amount": paid_amount,
            "tax_amount": tax_amount,
            "insurance_coverage": insurance_coverage,
        }

        billings.append(billing)

        index += 1

    return billings


if __name__ == '__main__':
    departments = get_departments()
    doctors = generate_doctors(departments)
    patients = generate_patients()
    visits = generate_visits(doctors, patients)
    treatments = generate_treatments(visits, departments)
    medications = generate_medications(treatments, visits)
    billings = generate_billing(visits, treatments, medications)

    all_data = [("Department", departments), ("Doctor", doctors), ("Patient", patients), ("Visit", visits),
                ("Treatment", treatments),
                ("Medication", medications),
                ("Billing", billings)]

    print("Visit Count: ", len(visits))
    print("Treatment Count: ", len(treatments))
    print("Medication Count: ", len(medications))
    print("Billing Count: ", len(billings))

    produce_sql_and_insert_into(all_data)
