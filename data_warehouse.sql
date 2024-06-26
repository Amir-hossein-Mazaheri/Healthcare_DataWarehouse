use data_warehouse
go
drop schema if exists Warehouse;

use data_warehouse
go
create schema Warehouse;

-- drop tables
drop table if exists data_warehouse.Warehouse.Dim_Time
drop table if exists data_warehouse.Warehouse.Dim_Billing
drop table if exists data_warehouse.Warehouse.Dim_Medication
drop table if exists data_warehouse.Warehouse.Dim_Treatment
drop table if exists data_warehouse.Warehouse.Dim_Visit
drop table if exists data_warehouse.Warehouse.Dim_Patient
drop table if exists data_warehouse.Warehouse.Dim_Doctor
drop table if exists data_warehouse.Warehouse.Dim_Department

-- dimensions

-- This dimension should be filled from the time dimension generator and the procedures assume
-- this dimension is filled
create table data_warehouse.Warehouse.Dim_Time
(
    time_key                        date unique  not null,
    full_date_alternate_day         nvarchar(50) not null,
    persian_full_date_alternate_day nvarchar(50) not null,
    day_number_of_week              int          not null,
    persian_number_of_week          int          not null,
    day_name_of_week                nvarchar(50) not null,
    persian_day_name_of_week        nvarchar(50) not null,
    day_number_of_month             int          not null,
    persian_day_number_of_month     int          not null,
    day_number_of_year              int          not null,
    persian_day_number_of_year      int          not null,
    week_number_of_year             int          not null,
    persian_week_number_of_year     int          not null,
    month_name                      nvarchar(50) not null,
    month_number_of_year            int          not null,
    persian_month_number_of_year    int          not null,
    persian_month_name              nvarchar(50) not null,
    calendar_quarter                int          not null,
    persian_calendar_quarter        int          not null,
    calendar_year                   int          not null,
    persian_calendar_year           int          not null,
)
go

create table data_warehouse.Warehouse.Dim_Department
(
    department_id   int           not null,
    department_name nvarchar(512) not null,
)
go

-- Doctor specialization is a SCD type 3
create table data_warehouse.Warehouse.Dim_Doctor
(
    doctor_id                     int           not null,
    national_code                 nvarchar(15)  not null,
    firstname                     nvarchar(512) not null,
    lastname                      nvarchar(512) not null,
    gender                        nvarchar(20)  not null check (gender in ('men', 'woman')),
    phone                         nvarchar(15)  not null,
    original_specialization       nvarchar(255) null,
    current_specialization        nvarchar(255) not null,
    specialization_effective_date date          null,
    department_id                 int           not null,
    department_name               nvarchar(512) not null,
)
go


-- Patient phone is SCD type 2
create table data_warehouse.Warehouse.Dim_Patient
(
    patient_surrogate_key int           not null,
    patient_id            int           not null,
    national_code         nvarchar(15)  not null,
    firstname             nvarchar(512) not null,
    lastname              nvarchar(512) not null,
    dob                   Date          not null, -- date of birthday
    gender                nvarchar(20)  not null check (gender in ('men', 'woman')),
    phone                 nvarchar(15)  not null,
    phone_start_date      date          not null,
    phone_end_date        date          null,
    phone_current_flag    bit           not null,
)
go

create table data_warehouse.Warehouse.Dim_Visit
(
    visit_id              int            not null,
    visit_date            DATETIME       not null,
    diagnosis             nvarchar(max)  not null,
    visit_cost            decimal(15, 4) not null,
    is_check_up           BIT            not null, -- 0 for False and 1 for True
    patient_id            int            not null,
    patient_national_code nvarchar(15)   not null,
    patient_firstname     nvarchar(512)  not null,
    patient_lastname      nvarchar(512)  not null,
    patient_dob           Date           not null, -- date of birthday
    patient_gender        nvarchar(20)   not null check (patient_gender in ('men', 'woman')),
    patient_phone         nvarchar(15)   not null,
    doctor_id             int            not null,
    doctor_national_code  nvarchar(15)   not null,
    doctor_firstname      nvarchar(512)  not null,
    doctor_lastname       nvarchar(512)  not null,
    doctor_gender         nvarchar(20)   not null check (doctor_gender in ('men', 'woman')),
    doctor_phone          nvarchar(15)   not null,
    doctor_specialization nvarchar(255)  not null,
    department_id         int            not null,
    department_name       nvarchar(512)  not null,
    treatment_id          int            null,
    treatment_type        nvarchar(255),
    treatment_description nvarchar(max),
    treatment_cost        decimal(15, 4),
    medication_id         int            null,
    medication_name       nvarchar(512),
    dosage                decimal(12, 4),
    frequency             int,
    frequency_unit        nvarchar(255) check (frequency_unit in ('minute', 'hour', 'day', 'week', 'month')),
    medication_cost       decimal(15, 4),
    prescription_date     date,
    duration              int,
    billing_id            int            not null,
    total_amount          decimal(15, 4) not null,
    paid_amount           decimal(15, 4) not null,
    tax_amount            decimal(15, 4) not null,
    insurance_coverage    decimal(15, 4) not null,
)
go

create table data_warehouse.Warehouse.Dim_Treatment
(
    treatment_id          int            not null,
    visit_id              int            not null,
    treatment_type        nvarchar(255)  not null,
    treatment_description nvarchar(max)  not null,
    treatment_cost        decimal(15, 4) not null,
    department_id         int            not null,
    department_name       nvarchar(512)  not null,
)
go

create table data_warehouse.Warehouse.Dim_Medication
(
    medication_id     int            not null,
    visit_id          int            not null,
    medication_name   nvarchar(512)  not null,
    dosage            decimal(12, 4) not null,
    frequency         int            not null,
    frequency_unit    nvarchar(255)  not null check (frequency_unit in ('minute', 'hour', 'day', 'week', 'month')),
    medication_cost   decimal(15, 4) not null,
    prescription_date date           not null,
    duration          int            not null,
)
go

create table data_warehouse.Warehouse.Dim_Billing
(
    billing_id         int            not null,
    visit_id           int            not null,
    total_amount       decimal(15, 4) not null,
    paid_amount        decimal(15, 4) not null,
    tax_amount         decimal(15, 4) not null,
    insurance_coverage decimal(15, 4) not null,
)
go

-- Facts
drop table if exists data_warehouse.Warehouse.Fact_Visit_Transactional;
drop table if exists data_warehouse.Warehouse.Fact_Patient_Daily;
drop table if exists data_warehouse.Warehouse.Fact_Patient_ACC;
drop table if exists data_warehouse.Warehouse.Fact_Patient_Doctor_Factless;

-- Transactional Fact
create table data_warehouse.Warehouse.Fact_Visit_Transactional
(
    visit_id                 int            not null,
    patient_surrogate_key    int            not null,
    department_id            int            not null,
    doctor_id                int            not null,
    treatment_id             int            not null,
    medication_id            int            not null,
    time_key                 date           not null,

    -- measures
    total_cost               decimal(15, 4) not null,
    total_insurance_coverage decimal(15, 4) not null,
    total_paid               decimal(15, 4) not null, -- total cost is the sum of total_insurance_cost and total_paid
    total_medication_cost    decimal(15, 4) not null,
    total_treatment_cost     decimal(15, 4) not null,
)
go

-- Periodic Snapshot Fact(Daily)
create table data_warehouse.Warehouse.Fact_Patient_Daily
(
    patient_surrogate_key    int            not null,
    time_key                 date           not null,

    -- measures
    total_visits             int            not null,
    total_treatments         int            not null,
    total_medications        int            not null,
    -- all cost fields are accumulative
    total_cost               decimal(15, 4) not null,
    total_insurance_coverage decimal(15, 4) not null,
    total_paid               decimal(15, 4) not null,
    current_treatment_type   nvarchar(255)  not null,
    current_medication_name  nvarchar(512)  not null,
)
go

-- Accumulative Fact
create table data_warehouse.Warehouse.Fact_Patient_ACC
(
    patient_surrogate_key   int            not null,

    -- measures
    total_visits            bigint         not null,
    total_treatments        bigint         not null,
    total_medications       bigint         not null,
    total_cost              decimal(15, 4) not null,
    total_visits_cost       decimal(15, 4) not null,
    total_treatments_cost   decimal(15, 4) not null,
    total_medications_cost  decimal(15, 4) not null,
    current_treatment_type  nvarchar(255)  not null,
    current_medication_name nvarchar(512)  not null,
    patient_age             int            not null,
)
go

-- Factless Fact
create table data_warehouse.Warehouse.Fact_Patient_Doctor_Factless
(

    patient_surrogate_key int not null,
    doctor_id             int not null,
)

-- procedures