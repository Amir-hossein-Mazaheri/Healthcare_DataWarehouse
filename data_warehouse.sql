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
drop table if exists data_warehouse.Warehouse.Fact_Visit_Transactional
drop table if exists data_warehouse.Warehouse.Fact_Patient_Daily
drop table if exists data_warehouse.Warehouse.Fact_Patient_ACC
drop table if exists data_warehouse.Warehouse.Fact_Patient_Doctor_Factless
drop table if exists data_warehouse.Warehouse.Log

-- log table

create table data_warehouse.Warehouse.Log
(
    log_id         int identity (1, 1) not null,
    operation_name nvarchar(255)       not null,
    target_table   nvarchar(255)       not null,
    type           nvarchar(100)       not null,
    created_at     datetime default getdate()
)
go

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
    persian_month_name              nvarchar(50) not null,
    month_number_of_year            int          not null,
    persian_month_number_of_year    int          not null,
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
    patient_surrogate_key int identity (1, 1) not null,
    patient_id            int                 not null,
    national_code         nvarchar(15)        not null,
    firstname             nvarchar(512)       not null,
    lastname              nvarchar(512)       not null,
    dob                   Date                not null, -- date of birthday
    gender                nvarchar(20)        not null check (gender in ('men', 'woman')),
    phone                 nvarchar(15)        not null,
    phone_start_date      date                not null,
    phone_end_date        date                null,
    phone_current_flag    bit                 not null,
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
    billing_id               int            not null,
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
    -- all measures are accumulative
    total_visits             int            not null,
    total_treatments         int            not null,
    total_medications        int            not null,
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
    patient_surrogate_key    int            not null,

    -- measures
    total_visits             bigint         not null,
    total_treatments         bigint         not null,
    total_medications        bigint         not null,
    total_cost               decimal(15, 4) not null,
    total_insurance_coverage decimal(15, 4) not null,
    total_paid               decimal(15, 4) not null,
    total_visits_cost        decimal(15, 4) not null,
    total_treatments_cost    decimal(15, 4) not null,
    total_medications_cost   decimal(15, 4) not null,
    current_treatment_type   nvarchar(255)  not null,
    current_medication_name  nvarchar(512)  not null,
    patient_age              int            not null,
)
go

-- Factless Fact
create table data_warehouse.Warehouse.Fact_Patient_Doctor_Factless
(

    patient_surrogate_key int not null,
    doctor_id             int not null,
)
go

-- procedures

-- drop procedures
drop procedure if exists Warehouse.create_log;
drop procedure if exists Warehouse.ins_dim_department;
drop procedure if exists Warehouse.first_load_dim_doctor;
drop procedure if exists Warehouse.ins_dim_doctor;
drop procedure if exists Warehouse.first_load_dim_patient;
drop procedure if exists Warehouse.ins_dim_patient;
drop procedure if exists Warehouse.ins_dim_visit;
drop procedure if exists Warehouse.ins_dim_treatment;
drop procedure if exists Warehouse.ins_dim_medication;
drop procedure if exists Warehouse.ins_dim_billing;
drop procedure if exists Warehouse.ins_fact_visit_transactional
drop procedure if exists Warehouse.ins_fact_patient_daily
drop procedure if exists Warehouse.ins_fact_patient_acc
drop procedure if exists Warehouse.main

-- helper procedures

create procedure Warehouse.create_log @operation_name nvarchar(255), @target_table nvarchar(255), @type nvarchar(100)
as
begin
    insert into data_warehouse.Warehouse.Log(operation_name, target_table, type)
    values (@operation_name, @target_table, @type)
end;
go

-- dimensions
-- Each dimension and fact has a routine procedure also a first load procedure

-- department
-- department dimension first load and insert procedures are the same because its super simple
create procedure Warehouse.ins_dim_department
as
begin
    if object_id('temp1', 'U') is not null
        begin
            if not exists(select * from data_warehouse.Warehouse.Dim_Department) and exists(select * from temp1)
                begin
                    raiserror ('Dim_Department is empty and temp1 is allocated something must have went wrong', 25, 1);
                end

            truncate table temp1;

            execute Warehouse.create_log 'ins_dim_department', 'temp1', 'truncate';
        end
    else
        begin
            select *
            into temp1
            from data_warehouse.Warehouse.Dim_Department
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_department', 'temp1', 'copy_schema';
        end

    insert into temp1
    select department_id, department_name
    from staging.Cache.Department

    execute Warehouse.create_log 'ins_dim_department', 'temp1', 'insert';

    truncate table data_warehouse.Warehouse.Dim_Department;

    execute Warehouse.create_log 'ins_dim_department', 'Dim_Department', 'truncate';

    insert into data_warehouse.Warehouse.Dim_Department
    select department_id, department_name
    from temp1

    execute Warehouse.create_log 'ins_dim_department', 'Dim_Department', 'insert';
end;
go

-- doctor
create procedure Warehouse.first_load_dim_doctor
as
begin
    if object_id('temp2', 'U') is not null
        begin
            if not exists(select * from data_warehouse.Warehouse.Dim_Doctor) and exists(select * from temp2)
                begin
                    raiserror ('Dim_Doctor is empty and temp2 is allocated something must have went wrong', 25, 1);
                end

            truncate table temp2;

            execute Warehouse.create_log 'first_load_dim_doctor', 'temp2', 'truncate';
        end
    else
        begin
            select *
            into temp2
            from data_warehouse.Warehouse.Dim_Doctor
            where 1 = 0

            execute Warehouse.create_log 'first_load_dim_doctor', 'temp2', 'copy_schema';
        end

    insert into temp2
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           null,
           specialization,
           null,
           department_id,
           department_name
    from staging.Cache.Doctor

    execute Warehouse.create_log 'first_load_dim_doctor', 'temp2', 'insert';

    truncate table data_warehouse.Warehouse.Dim_Doctor

    execute Warehouse.create_log 'first_load_dim_doctor', 'Dim_Doctor', 'truncate';

    insert into data_warehouse.Warehouse.Dim_Doctor
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           original_specialization,
           current_specialization,
           specialization_effective_date,
           department_id,
           department_name
    from temp2

    execute Warehouse.create_log 'first_load_dim_doctor', 'Dim_Doctor', 'insert';
end;
go

create procedure Warehouse.ins_dim_doctor
as
begin
    if object_id('temp3', 'U') is not null and object_id('temp4', 'U') is not null and
       object_id('temp5', 'U') is not null and object_id('temp6', 'U') is not null
        begin
            if not exists(select * from data_warehouse.Warehouse.Dim_Doctor) and exists(select * from temp6)
                begin
                    raiserror ('Dim_Doctor is empty and temp6 is allocated something must have went wrong', 25, 1);
                end

            truncate table temp3;

            execute Warehouse.create_log 'ins_dim_doctor', 'temp3', 'truncate';

            truncate table temp4;

            execute Warehouse.create_log 'ins_dim_doctor', 'temp4', 'truncate';

            truncate table temp5;

            execute Warehouse.create_log 'ins_dim_doctor', 'temp5', 'truncate';

            truncate table temp6;

            execute Warehouse.create_log 'ins_dim_doctor', 'temp6', 'truncate';
        end
    else
        begin
            select *
            into temp3
            from data_warehouse.Warehouse.Dim_Doctor
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_doctor', 'temp3', 'copy_schema';

            select *
            into temp4
            from data_warehouse.Warehouse.Dim_Doctor
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_doctor', 'temp4', 'copy_schema';

            select *
            into temp5
            from data_warehouse.Warehouse.Dim_Doctor
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_doctor', 'temp5', 'copy_schema';

            select *
            into temp6
            from data_warehouse.Warehouse.Dim_Doctor
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_doctor', 'temp6', 'copy_schema';
        end

    -- this just get the fresh doctors
    insert into temp3
    select d.doctor_id,
           d.national_code,
           d.firstname,
           d.lastname,
           d.gender,
           d.phone,
           null,
           d.specialization,
           null,
           d.department_id,
           d.department_name
    from staging.Cache.Doctor as d
             left join data_warehouse.Warehouse.Dim_Doctor as dd on (dd.doctor_id = d.doctor_id)
    where dd.doctor_id is null

    execute Warehouse.create_log 'ins_dim_doctor', 'temp3', 'insert';

    -- this create new records for the doctors whose specialization changes
    insert into temp4
    select d.doctor_id,
           d.national_code,
           d.firstname,
           d.lastname,
           d.gender,
           d.phone,
           dd.current_specialization,
           d.specialization,
           getdate(),
           d.department_id,
           d.department_name
    from data_warehouse.Warehouse.Dim_Doctor as dd
             inner join staging.Cache.Doctor as d
                        on (dd.doctor_id = d.doctor_id and dd.current_specialization != d.specialization)

    execute Warehouse.create_log 'ins_dim_doctor', 'temp4', 'insert';

    -- this table just get the unchanged doctors and other field in dim_doctor in SCD type 1 so
    -- any changes to those fields gets applied here
    insert into temp5
    select d.doctor_id,
           d.national_code,
           d.firstname,
           d.lastname,
           d.gender,
           d.phone,
           dd.original_specialization,
           dd.current_specialization,
           dd.specialization_effective_date,
           d.department_id,
           d.department_name
    from data_warehouse.Warehouse.Dim_Doctor as dd
             inner join staging.Cache.Doctor as d
                        on (dd.doctor_id = d.doctor_id and dd.current_specialization = d.specialization)

    execute Warehouse.create_log 'ins_dim_doctor', 'temp5', 'insert';

    insert into temp6
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           original_specialization,
           current_specialization,
           specialization_effective_date,
           department_id,
           department_name
    from temp3
    union all
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           original_specialization,
           current_specialization,
           specialization_effective_date,
           department_id,
           department_name
    from temp4
    union all
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           original_specialization,
           current_specialization,
           specialization_effective_date,
           department_id,
           department_name
    from temp5

    execute Warehouse.create_log 'ins_dim_doctor', 'temp6', 'insert';

    truncate table data_warehouse.Warehouse.Dim_Doctor

    execute Warehouse.create_log 'ins_dim_doctor', 'Dim_Doctor', 'truncate';

    insert into data_warehouse.Warehouse.Dim_Doctor
    select doctor_id,
           national_code,
           firstname,
           lastname,
           gender,
           phone,
           original_specialization,
           current_specialization,
           specialization_effective_date,
           department_id,
           department_name
    from temp6
end;
go

-- patient
create procedure Warehouse.first_load_dim_patient
as
begin
    if object_id('temp7', 'U') is not null
        begin
            if not exists(select * from data_warehouse.Warehouse.Dim_Patient) and exists(select * from temp7)
                begin
                    raiserror ('Dim_Patient is empty and temp7 is allocated something must have went wrong', 25, 1);
                end

            truncate table temp7;

            execute Warehouse.create_log 'first_load_dim_patient', 'temp7', 'truncate';
        end
    else
        begin
            select *
            into temp7
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'first_load_dim_doctor', 'temp7', 'copy_schema';
        end

    insert into temp7 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                       phone_end_date, phone_current_flag)
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           getdate(),
           null,
           1
    from staging.Cache.Patient

    execute Warehouse.create_log 'first_load_dim_patient', 'temp7', 'insert';

    truncate table data_warehouse.Warehouse.Dim_Patient

    execute Warehouse.create_log 'first_load_dim_patient', 'Dim_Patient', 'truncate';

    insert into data_warehouse.Warehouse.Dim_Patient (patient_id, national_code, firstname, lastname, dob, gender,
                                                      phone, phone_start_date,
                                                      phone_end_date, phone_current_flag)
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp7

    execute Warehouse.create_log 'first_load_dim_patient', 'Dim_Patient', 'insert';
end;
go

create procedure Warehouse.ins_dim_patient
as
begin
    if object_id('temp7', 'U') is not null and object_id('temp8', 'U') is not null and
       object_id('temp9', 'U') is not null and object_id('temp10', 'U') is not null and
       object_id('temp11', 'U') is not null
        begin
            if not exists(select * from data_warehouse.Warehouse.Dim_Patient) and exists(select * from temp11)
                begin
                    raiserror ('Dim_Patient is empty and temp11 is allocated something must have went wrong', 25, 1);
                end

            truncate table temp7;

            execute Warehouse.create_log 'ins_dim_patient', 'temp7', 'truncate';

            truncate table temp8;

            execute Warehouse.create_log 'ins_dim_patient', 'temp8', 'truncate';

            truncate table temp9;

            execute Warehouse.create_log 'ins_dim_patient', 'temp9', 'truncate';

            truncate table temp10;

            execute Warehouse.create_log 'ins_dim_patient', 'temp10', 'truncate';

            truncate table temp11;

            execute Warehouse.create_log 'ins_dim_patient', 'temp11', 'truncate';
        end
    else
        begin
            select *
            into temp7
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_patient', 'temp7', 'truncate';

            select *
            into temp8
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_patient', 'temp8', 'truncate';

            select *
            into temp9
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_patient', 'temp9', 'truncate';

            select *
            into temp10
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_patient', 'temp10', 'truncate';

            select *
            into temp11
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_dim_patient', 'temp11', 'truncate';
        end

    -- get the fresh patients
    insert into temp7 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                       phone_end_date, phone_current_flag)
    select p.patient_id,
           p.national_code,
           p.firstname,
           p.lastname,
           p.dob,
           p.gender,
           p.phone,
           getdate(),
           null,
           1
    from staging.Cache.Patient as p
             left join data_warehouse.Warehouse.Dim_Patient as dp on (p.patient_id = dp.patient_id)
    where dp.patient_id is null

    execute Warehouse.create_log 'ins_dim_patient', 'temp7', 'insert';

    -- create new record for patient whose phone is changes
    insert into temp8 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                       phone_end_date, phone_current_flag)
    select p.patient_id,
           p.national_code,
           p.firstname,
           p.lastname,
           p.dob,
           p.gender,
           p.phone,
           getdate(),
           null,
           1
    from data_warehouse.Warehouse.Dim_Patient as dp
             inner join staging.Cache.Patient as p
                        on (dp.patient_id = p.patient_id and dp.phone != p.phone)
    where dp.phone_current_flag = 1

    execute Warehouse.create_log 'ins_dim_patient', 'temp8', 'insert';

    -- also should change the phone_end_date and phone_current_flag for the records that are old
    insert into temp9 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                       phone_end_date, phone_current_flag)
    select dp.patient_id,
           dp.national_code,
           dp.firstname,
           dp.lastname,
           dp.dob,
           dp.gender,
           dp.phone,
           dp.phone_start_date,
           getdate(),
           0
    from data_warehouse.Warehouse.Dim_Patient as dp
             inner join temp8 as t on (dp.patient_id = t.patient_id)
    where dp.phone_current_flag = 1

    execute Warehouse.create_log 'ins_dim_patient', 'temp9', 'insert';

    -- other fields in dim_patient are SCD type 1 so this section makes sure that any changes are applies
    insert into temp10 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                        phone_end_date, phone_current_flag)
    select p.patient_id,
           p.national_code,
           p.firstname,
           p.lastname,
           p.dob,
           p.gender,
           dp.phone,
           dp.phone_start_date,
           dp.phone_end_date,
           dp.phone_current_flag
    from data_warehouse.Warehouse.Dim_Patient as dp
             inner join staging.Cache.Patient as p on (dp.patient_id = p.patient_id and dp.phone = p.phone)
    where dp.phone_current_flag = 1

    execute Warehouse.create_log 'ins_dim_patient', 'temp10', 'insert';

    -- gather all records into temp11
    insert into temp11 (patient_id, national_code, firstname, lastname, dob, gender, phone, phone_start_date,
                        phone_end_date, phone_current_flag)
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp7
    union all
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp8
    union all
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp9
    union all
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp10

    execute Warehouse.create_log 'ins_dim_patient', 'temp11', 'insert';

    truncate table data_warehouse.Warehouse.Dim_Patient

    execute Warehouse.create_log 'ins_dim_patient', 'Dim_Patient', 'truncate';

    insert into data_warehouse.Warehouse.Dim_Patient
    select patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           gender,
           phone,
           phone_start_date,
           phone_end_date,
           phone_current_flag
    from temp11

    execute Warehouse.create_log 'ins_dim_patient', 'Dim_Patient', 'insert';
end;
go

-- visit
create procedure Warehouse.ins_dim_visit @start_date date, @end_date date
as
begin
    -- because this is the first load it doesn't get start_date and end_date
    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            insert into data_warehouse.Warehouse.Dim_Visit
            select visit_id,
                   visit_date,
                   diagnosis,
                   visit_cost,
                   is_check_up,
                   patient_id,
                   patient_national_code,
                   patient_firstname,
                   patient_lastname,
                   patient_dob,
                   patient_gender,
                   patient_phone,
                   doctor_id,
                   doctor_national_code,
                   doctor_firstname,
                   doctor_lastname,
                   doctor_gender,
                   doctor_phone,
                   specialization,
                   department_id,
                   department_name,
                   treatment_id,
                   treatment_type,
                   treatment_description,
                   treatment_cost,
                   medication_id,
                   medication_name,
                   dosage,
                   frequency,
                   frequency_unit,
                   medication_cost,
                   prescription_date,
                   duration,
                   billing_id,
                   total_amount,
                   paid_amount,
                   tax_amount,
                   insurance_coverage
            from staging.Cache.Visit
            where visit_date >= @current_date
              and visit_date < DATEADD(day, 1, @current_date)

            -- just add a counter to make it less confusing
            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_dim_visit', 'Dim_Visit', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- treatment
create procedure Warehouse.ins_dim_treatment @start_date date, @end_date date
as
begin
    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            insert into data_warehouse.Warehouse.Dim_Treatment
            select t.treatment_id,
                   t.treatment_type,
                   t.treatment_description,
                   t.treatment_cost,
                   t.department_id,
                   t.department_name
            from staging.Cache.Treatment as t
                     inner join (select visit_id
                                 from staging.Cache.Visit
                                 where visit_date >= @current_date
                                   and visit_date < DATEADD(day, 1, @current_date)) as v
                                on (t.visit_id = v.visit_id)

            -- just add a counter to make it less confusing
            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_dim_treatment', 'Dim_Treatment', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- medication
create procedure Warehouse.ins_dim_medication @start_date date, @end_date date
as
begin
    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            select medication_id,
                   medication_name,
                   dosage,
                   frequency,
                   frequency_unit,
                   medication_cost,
                   prescription_date,
                   duration
            from staging.Cache.Medication
            where prescription_date >= @current_date
              and prescription_date < DATEADD(day, 1, @current_date)

            -- just add a counter to make it less confusing
            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_dim_medication', 'Dim_Medication', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- billing
create procedure Warehouse.ins_dim_billing @start_date date, @end_date date
as
begin
    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            insert into data_warehouse.Warehouse.Dim_Billing
            select billing_id, total_amount, paid_amount, tax_amount, insurance_coverage
            from staging.Cache.Billing as b
                     inner join (select visit_id
                                 from staging.Cache.Visit
                                 where visit_date >= @current_date
                                   and visit_date < DATEADD(day, 1, @current_date)) as v
                                on (b.visit_id = v.visit_id)

            -- just add a counter to make it less confusing
            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_dim_billing', 'Dim_Billing', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- facts

-- Transactional Fact
create procedure Warehouse.ins_fact_visit_transactional @start_date date, @end_date date
as
begin
    if object_id('temp_visits', 'U') is null and object_id('temp_visits_with_surrogate_key', 'U') is null
        begin
            select *
            into temp_visits
            from data_warehouse.Warehouse.Fact_Visit_Transactional
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits', 'copy-schema';

            select *
            into temp_visits_with_surrogate_key
            from data_warehouse.Warehouse.Fact_Visit_Transactional
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits_with_surrogate_key',
                    'copy-schema';
        end

    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            set @type = 'truncate ' + cast(@current_date as nvarchar(20))

            truncate table temp_visits;

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits', @type;

            truncate table temp_visits_with_surrogate_key;

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits_with_surrogate_key', @type;

            insert into temp_visits
            select visit_id,
                   patient_id,
                   department_id,
                   doctor_id,
                   treatment_id,
                   medication_id,
                   billing_id,
                   @current_date,
                   total_amount,
                   medication_cost,
                   treatment_cost,
                   insurance_coverage,
                   paid_amount
            from (select visit_id,
                         patient_id,
                         department_id,
                         doctor_id,
                         treatment_id,
                         medication_id,
                         billing_id,
                         total_amount,
                         medication_cost,
                         treatment_cost,
                         insurance_coverage,
                         paid_amount
                  from data_warehouse.Warehouse.Dim_Visit
                  where visit_date >= @current_date
                    and visit_date < DATEADD(day, 1, @current_date)) as v

            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits', @type;

            insert into temp_visits_with_surrogate_key
            select t.visit_id,
                   dp.patient_surrogate_key,
                   t.department_id,
                   t.doctor_id,
                   t.treatment_id,
                   t.medication_id,
                   t.billing_id,
                   @current_date,
                   t.total_amount,
                   t.medication_cost,
                   t.treatment_cost,
                   t.insurance_coverage,
                   t.paid_amount
            from temp_visits as t
                     inner join data_warehouse.Warehouse.Dim_Patient as dp on (t.patient_id = dp.patient_id)
            where dp.phone_current_flag = 1

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'temp_visits_with_surrogate_key', @type;

            insert into data_warehouse.Warehouse.Fact_Visit_Transactional
            select visit_id,
                   patient_surrogate_key,
                   department_id,
                   doctor_id,
                   treatment_id,
                   medication_id,
                   billing_id,
                   @current_date,
                   total_amount,
                   insurance_coverage,
                   paid_amount,
                   medication_cost,
                   treatment_cost
            from temp_visits_with_surrogate_key

            execute Warehouse.create_log 'ins_fact_visit_transactional', 'Fact_Visit_Transactional', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- Daily Fact
create procedure Warehouse.ins_fact_patient_daily @start_date date, @end_date date
as
begin
    if object_id('temp_all_patients', 'U') is null and object_id('temp_today_visits', 'U') is null and
       object_id('temp_patient_visits', 'U') is null and object_id('temp_last_treatments', 'U') is null and
       object_id('temp_last_medications', 'U') is null and object_id('temp_full_patient_visits', 'U') is null and
       object_id('temp_full_patient_visits_accumulative', 'U') is null
        begin
            -- 1
            select patient_surrogate_key, patient_id
            into temp_all_patients
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_all_patients', 'copy-schema';

            -- 2
            select *
            into temp_today_visits
            from data_warehouse.Warehouse.Dim_Visit
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_today_visits', 'copy-schema';

            -- 3
            select patient_surrogate_key,
                   time_key,
                   total_visits,
                   total_treatments,
                   total_medications,
                   total_cost,
                   total_insurance_coverage,
                   total_paid
            into temp_patient_visits
            from data_warehouse.Warehouse.Fact_Patient_Daily
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_patient_visits', 'copy-schema';

            -- 4
            select patient_id, treatment_type
            into temp_last_treatments
            from data_warehouse.Warehouse.Dim_Visit
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_treatments', 'copy-schema';

            -- 5
            select patient_id, medication_name
            into temp_last_medications
            from data_warehouse.Warehouse.Dim_Visit
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_medications', 'copy-schema';

            -- 6
            select *
            into temp_full_patient_visits
            from data_warehouse.Warehouse.Fact_Patient_Daily
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits', 'copy-schema';

            -- 7
            select *
            into temp_full_patient_visits_accumulative
            from data_warehouse.Warehouse.Fact_Patient_Daily
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits_accumulative',
                    'copy-schema';
        end

    declare @type nvarchar(255);
    declare @current_date date = @start_date;

    while @current_date <= @end_date
        begin
            set @type = 'truncate ' + cast(@current_date as nvarchar(20))

            truncate table temp_all_patients

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_all_patients', @type;

            truncate table temp_today_visits

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_today_visits', @type;

            truncate table temp_patient_visits

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_patient_visits', @type;

            truncate table temp_last_treatments

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_treatments', @type;

            truncate table temp_last_medications

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_medications', @type;

            truncate table temp_full_patient_visits

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits', @type;

            truncate table temp_full_patient_visits_accumulative

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits_accumulative', @type;

            insert into temp_all_patients
            select patient_surrogate_key, patient_id
            from data_warehouse.Warehouse.Dim_Patient
            where phone_current_flag = 1

            set @type = 'insert ' + cast(@current_date as nvarchar(20))
            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_all_patients', @type;

            insert into temp_today_visits
            select visit_id,
                   visit_date,
                   diagnosis,
                   visit_cost,
                   is_check_up,
                   patient_id,
                   patient_national_code,
                   patient_firstname,
                   patient_lastname,
                   patient_dob,
                   patient_gender,
                   patient_phone,
                   doctor_id,
                   doctor_national_code,
                   doctor_firstname,
                   doctor_lastname,
                   doctor_gender,
                   doctor_phone,
                   doctor_specialization,
                   department_id,
                   department_name,
                   treatment_id,
                   treatment_type,
                   treatment_description,
                   treatment_cost,
                   medication_id,
                   medication_name,
                   dosage,
                   frequency,
                   frequency_unit,
                   medication_cost,
                   prescription_date,
                   duration,
                   billing_id,
                   total_amount,
                   paid_amount,
                   tax_amount,
                   insurance_coverage
            from data_warehouse.Warehouse.Dim_Visit
            where visit_date >= @current_date
              and visit_date < DATEADD(day, 1, @current_date)

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_today_visits', @type;

            insert into temp_patient_visits
            select p.patient_surrogate_key,
                   @current_date,
                   count(v.visit_id),
                   count(v.treatment_id),
                   count(v.medication_id),
                   sum(v.total_amount),
                   sum(v.insurance_coverage),
                   sum(v.paid_amount)
            from temp_all_patients as p
                     left join temp_today_visits as v on (v.patient_id = p.patient_id)
            group by p.patient_surrogate_key, p.patient_id

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_patient_visits', @type;


            insert into temp_last_treatments
            select patient_id, treatment_type
            from (select max(visit_id) as last_visit_with_treatment
                  from temp_today_visits
                  where is_check_up = 0
                    and medication_id is not null
                  group by patient_id) as lv
                     inner join temp_today_visits as v
                                on (lv.last_visit_with_treatment = v.visit_id)

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_treatments', @type;

            insert into temp_last_medications
            select patient_id, medication_name
            from (select max(visit_id) as last_visit_with_medication
                  from temp_today_visits
                  where is_check_up = 0
                    and medication_id is not null
                  group by patient_id) as lv
                     inner join temp_today_visits as v
                                on (lv.last_visit_with_medication = v.visit_id)

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_last_medications', @type;

            insert into temp_full_patient_visits
            select patient_surrogate_key,
                   time_key,
                   total_visits,
                   total_treatments,
                   total_medications,
                   total_cost,
                   total_insurance_coverage,
                   total_paid,
                   tt.treatment_type,
                   tm.medication_name
            from (select *
                  from temp_patient_visits as tv
                           inner join temp_all_patients as tp
                                      on (tv.patient_surrogate_key = tp.patient_surrogate_key)) as v
                     inner join temp_last_treatments as tt on (v.patient_id = tt.patient_id)
                     inner join temp_last_medications as tm on (v.patient_id = tm.patient_id)

            execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits', @type;

            if not exists(select * from data_warehouse.Warehouse.Fact_Patient_Daily)
                begin
                    -- this part only run for the first day in the first run
                    insert into temp_full_patient_visits_accumulative
                    select patient_surrogate_key,
                           time_key,
                           total_visits,
                           total_treatments,
                           total_medications,
                           total_cost,
                           total_insurance_coverage,
                           total_paid,
                           current_treatment_type,
                           current_medication_name
                    from temp_full_patient_visits

                    execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits_accumulative',
                            @type;
                end
            else
                begin
                    -- to make it simple it get the previous record for each patient and accumulate the measures
                    insert into temp_full_patient_visits_accumulative
                    select p1.patient_surrogate_key,
                           p1.time_key,
                           p1.total_visits + pd.total_visits,
                           p1.total_treatments + pd.total_treatments,
                           p1.total_medications + pd.total_medications,
                           p1.total_cost + pd.total_cost,
                           p1.total_insurance_coverage + pd.total_insurance_coverage,
                           p1.total_paid + pd.total_paid,
                           p1.current_treatment_type,
                           p1.current_medication_name
                    from temp_full_patient_visits as p1
                             inner join temp_today_visits as t1
                                        on (t1.patient_surrogate_key = p1.patient_surrogate_key)
                             inner join (select dp.patient_id,
                                                total_visits,
                                                total_treatments,
                                                total_medications,
                                                total_cost,
                                                total_insurance_coverage,
                                                total_paid
                                         from data_warehouse.Warehouse.Fact_Patient_Daily as fpd
                                                  inner join data_warehouse.Warehouse.Dim_Patient as dp
                                                             on (fpd.patient_surrogate_key = dp.patient_surrogate_key)
                                         where time_key <= DATEADD(day, -1, @current_date)
                                           and time_key > @current_date) as pd
                                        on (t1.patient_id = pd.patient_id)

                    execute Warehouse.create_log 'ins_fact_patient_daily', 'temp_full_patient_visits_accumulative',
                            @type;
                end


            insert into data_warehouse.Warehouse.Fact_Patient_Daily
            select patient_surrogate_key,
                   time_key,
                   total_visits,
                   total_treatments,
                   total_medications,
                   total_cost,
                   total_insurance_coverage,
                   total_paid,
                   current_treatment_type,
                   current_medication_name
            from temp_full_patient_visits_accumulative

            execute Warehouse.create_log 'ins_fact_patient_daily', 'Fact_Patient_Daily', @type;

            set @current_date = DATEADD(day, 1, @current_date)
        end
end;
go

-- Fact ACC
create procedure Warehouse.ins_fact_patient_acc
as
begin
    if object_id('temp_patients_with_age', 'U') is null and object_id('temp_last_day_patients', 'U') is null and
       object_id('temp_other_costs', 'U') is null and object_id('temp_fact_acc', 'U') is null
        begin
            select patient_surrogate_key, patient_id, dob
            into temp_patients_with_age
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_patients', 'copy-schema';

            select patient_surrogate_key,
                   total_visits,
                   total_treatments,
                   total_medications,
                   total_cost,
                   total_insurance_coverage,
                   total_paid,
                   current_treatment_type,
                   current_medication_name
            into temp_last_day_patients
            from data_warehouse.Warehouse.Fact_Patient_ACC
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_last_day_patients', 'copy-schema';

            select patient_surrogate_key, total_treatments_cost, total_medications_cost, patient_age
            into temp_other_costs
            from data_warehouse.Warehouse.Fact_Patient_ACC
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_other_costs', 'copy-schema';

            select *
            into temp_fact_acc
            from data_warehouse.Warehouse.Fact_Patient_ACC
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_fact_acc', 'copy-schema';
        end
    else
        begin
            if not exists(select * from data_warehouse.Warehouse.Fact_Patient_ACC) and
               exists(select * from temp_fact_acc)
                begin
                    raiserror ('Fact_Patient_ACC is empty and temp_fact_acc is allocated something must have went wrong', 25, 1);
                end

            truncate table temp_patients_with_age;

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_patients', 'truncate';

            truncate table temp_last_day_patients;

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_last_day_patients', 'truncate';

            truncate table temp_other_costs;

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_other_costs', 'truncate';

            truncate table temp_fact_acc

            execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_fact_acc', 'truncate';
        end

    insert into temp_patients_with_age
    select patient_surrogate_key, dob
    from data_warehouse.Warehouse.Dim_Patient
    where phone_current_flag = 1

    execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_patients_with_age', 'insert';

    insert into temp_last_day_patients
    select patient_surrogate_key,
           total_visits,
           total_treatments,
           total_medications,
           total_cost,
           total_insurance_coverage,
           total_paid,
           current_treatment_type,
           current_medication_name
    from data_warehouse.Warehouse.Fact_Patient_Daily
    where time_key >= (select max(time_key)
                       from data_warehouse.Warehouse.Fact_Patient_Daily)

    execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_last_day_patients', 'insert';

    insert into temp_other_costs
    select tp.patient_surrogate_key,
           total_treatments_cost,
           total_medications_cost,
           total_visits_cost,
           DATEDIFF(YEAR, tp.dob, GETDATE()) -
           CASE
               WHEN DATEADD(YEAR, DATEDIFF(YEAR, tp.dob, GETDATE()), tp.dob) > GETDATE()
                   THEN 1
               ELSE 0
               END AS patient_age
    from (select patient_id,
                 sum(treatment_cost)  as total_treatments_cost,
                 sum(medication_cost) as total_medications_cost,
                 sum(visit_cost)      as total_visits_cost
          from staging.Cache.Visit
          group by patient_id) as v
             inner join temp_patients_with_age as tp on (tp.patient_id = v.patient_id)

    execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_other_costs', 'insert';

    insert into temp_fact_acc
    select p.patient_surrogate_key,
           p.total_visits,
           p.total_treatments,
           p.total_medications,
           p.total_cost,
           p.total_insurance_coverage,
           p.total_paid,
           c.total_visits_cost,
           c.total_treatments_cost,
           c.total_medications_cost,
           p.current_treatment_type,
           p.current_medication_name,
           c.patient_age
    from temp_last_day_patients as p
             inner join temp_other_costs as c on (p.patient_surrogate_key = c.patient_surrogate_key)

    execute Warehouse.create_log 'ins_fact_patient_acc', 'temp_fact_acc', 'insert';

    truncate table data_warehouse.Warehouse.Fact_Patient_ACC

    execute Warehouse.create_log 'ins_fact_patient_acc', 'Fact_Patient_ACC', 'truncate';

    insert into data_warehouse.Warehouse.Fact_Patient_ACC
    select patient_surrogate_key,
           total_visits,
           total_treatments,
           total_medications,
           total_cost,
           total_insurance_coverage,
           total_paid,
           total_visits_cost,
           total_treatments_cost,
           total_medications_cost,
           current_treatment_type,
           current_medication_name,
           patient_age
    from temp_fact_acc

    execute Warehouse.create_log 'ins_fact_patient_acc', 'Fact_Patient_ACC', 'insert';
end;
go

-- Fact Factless
create procedure Warehouse.ins_fact_patient_doctor_factless
as
begin
    if object_id('temp_patients', 'U') is null and object_id('temp_fact_factless', 'U') is null
        begin
            select patient_surrogate_key, patient_id
            into temp_patients
            from data_warehouse.Warehouse.Dim_Patient
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_patients', 'copy-schema';

            select *
            into temp_fact_factless
            from data_warehouse.Warehouse.Fact_Patient_Doctor_Factless
            where 1 = 0

            execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_fact_factless', 'copy-schema';
        end
    else
        begin
            if not exists(select * from data_warehouse.Warehouse.Fact_Patient_Doctor_Factless) and
               exists(select * from temp_fact_factless)
                begin
                    raiserror ('Fact_Patient_Doctor_Factless is empty and temp_fact_factless is allocated something must have went wrong', 25, 1);
                end

            truncate table temp_patients;

            execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_patients', 'truncate';

            truncate table temp_fact_factless;

            execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_fact_factless', 'truncate';
        end

    insert into temp_patients
    select patient_surrogate_key, patient_id
    from data_warehouse.Warehouse.Dim_Patient
    where phone_current_flag = 1

    execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_patients', 'insert';

    insert into temp_fact_factless
    select p.patient_surrogate_key, pd.doctor_id
    from (select patient_id, doctor_id
          from staging.Cache.Visit
          group by patient_id, doctor_id) as pd
             inner join temp_patients as p on (pd.patient_id = p.patient_id)

    execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'temp_fact_factless', 'insert';

    truncate table data_warehouse.Warehouse.Fact_Patient_Doctor_Factless

    execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'Fact_Patient_Doctor_Factless', 'truncate';

    insert into data_warehouse.Warehouse.Fact_Patient_Doctor_Factless
    select patient_surrogate_key, doctor_id
    from temp_fact_factless

    execute Warehouse.create_log 'ins_fact_patient_doctor_factless', 'Fact_Patient_Doctor_Factless', 'insert';
end;
go

create procedure Warehouse.main
as
begin
    -- run SA main ETL procedure
--     execute staging.Cache.main;

    execute data_warehouse.Warehouse.ins_dim_department;

    if exists(select * from data_warehouse.Warehouse.Dim_Doctor)
        begin
            execute data_warehouse.Warehouse.first_load_dim_doctor;
        end
    else
        begin
            execute data_warehouse.Warehouse.ins_dim_doctor;
        end

    if exists(select * from data_warehouse.Warehouse.Dim_Patient)
        begin
            execute data_warehouse.Warehouse.first_load_dim_patient;
        end
    else
        begin
            execute data_warehouse.Warehouse.ins_dim_patient;
        end

    declare @start_visit_date date;
    declare @end_visit_date date;

    if exists(select * from data_warehouse.Warehouse.Dim_Visit)
        begin
            select @start_visit_date = DATEADD(day, 1, max(visit_date))
            from data_warehouse.Warehouse.Dim_Visit

            select @end_visit_date = max(visit_date)
            from staging.Cache.Visit
        end
    else
        begin
            select @start_visit_date = min(visit_date), @end_visit_date = max(visit_date)
            from staging.Cache.Visit
        end

    execute data_warehouse.Warehouse.ins_dim_visit @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_dim_treatment @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_dim_medication @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_dim_billing @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_fact_visit_transactional @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_fact_patient_daily @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_fact_patient_daily @start_visit_date, @end_visit_date;

    execute data_warehouse.Warehouse.ins_fact_patient_acc;

    execute data_warehouse.Warehouse.ins_fact_patient_doctor_factless;
end;
go

execute data_warehouse.Warehouse.main

truncate table Warehouse.Dim_Department
truncate table Warehouse.Dim_Doctor
truncate table Warehouse.Dim_Patient
truncate table Warehouse.Dim_Visit
truncate table Warehouse.Dim_Treatment
truncate table Warehouse.Dim_Medication
truncate table Warehouse.Dim_Billing
truncate table Warehouse.Fact_Visit_Transactional
truncate table Warehouse.Fact_Patient_Daily
truncate table Warehouse.Fact_Patient_ACC
truncate table Warehouse.Fact_Patient_Doctor_Factless

use msdb



