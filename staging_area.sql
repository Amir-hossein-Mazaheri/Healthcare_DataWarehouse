use staging
go
drop schema if exists Cache;

use staging
go
create schema Cache;

-- drop tables
drop table if exists staging.Cache.Billing
drop table if exists staging.Cache.Medication
drop table if exists staging.Cache.Treatment
drop table if exists staging.Cache.Visit
drop table if exists staging.Cache.Patient
drop table if exists staging.Cache.Doctor
drop table if exists staging.Cache.Department

-- create denormalized tables
create table staging.Cache.Department
(
    department_id   int           not null,
    department_name nvarchar(512) not null,
)
go

create table staging.Cache.Doctor
(
    doctor_id       int           not null,
    national_code   nvarchar(15)  not null,
    firstname       nvarchar(512) not null,
    lastname        nvarchar(512) not null,
    gender          nvarchar(20)  not null check (gender in ('men', 'woman')),
    phone           nvarchar(15)  not null,
    specialization  nvarchar(255) not null,
    department_id   int           not null,
    department_name nvarchar(512) not null,
)
go


create table staging.Cache.Patient
(
    patient_id    int           not null,
    national_code nvarchar(15)  not null,
    firstname     nvarchar(512) not null,
    lastname      nvarchar(512) not null,
    dob           Date          not null, -- date of birthday
    gender        nvarchar(20)  not null check (gender in ('men', 'woman')),
    phone         nvarchar(15)  not null,
)
go

create table staging.Cache.Visit
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
    specialization        nvarchar(255)  not null,
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

create table staging.Cache.Treatment
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

create table staging.Cache.Medication
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

create table staging.Cache.Billing
(
    billing_id         int            not null,
    visit_id           int            not null,
    total_amount       decimal(15, 4) not null,
    paid_amount        decimal(15, 4) not null,
    tax_amount         decimal(15, 4) not null,
    insurance_coverage decimal(15, 4) not null,
)
go

-- functions
drop function if exists Cache.convert_gender;

create function Cache.convert_gender(@gender Bit)
    returns nvarchar(20)
as
begin
    declare @result nvarchar(20);

    if @gender = 0
        begin
            set @result = 'woman'
        end
    else
        begin
            set @result = 'men'
        end

    return @result
end

-- procedures
drop procedure if exists Cache.fill_department
drop procedure if exists Cache.fill_doctor
drop procedure if exists Cache.fill_patient
drop procedure if exists Cache.fill_visit
drop procedure if exists Cache.fill_treatment
drop procedure if exists Cache.fill_medication
drop procedure if exists Cache.fill_billing
drop procedure if exists Cache.main

create procedure Cache.fill_department
as
begin
    truncate table staging.Cache.Department

    insert into staging.Cache.Department
    select d.department_id, d.department_name
    from source.Health.Department as d
end;
go

create procedure Cache.fill_doctor
as
begin
    truncate table staging.Cache.Doctor

    insert into staging.Cache.Doctor
    select doc.doctor_id,
           doc.national_code,
           doc.firstname,
           doc.lastname,
           staging.Cache.convert_gender(doc.gender),
           doc.phone,
           doc.specialization,
           dep.department_id,
           dep.department_name
    from source.Health.Doctor as doc
             join source.Health.Department as dep on (doc.department_id = dep.department_id)
end;
go

create procedure Cache.fill_patient
as
begin
    truncate table staging.Cache.Patient

    insert into staging.Cache.Patient
    select p.patient_id,
           national_code,
           firstname,
           lastname,
           dob,
           staging.Cache.convert_gender(gender),
           phone
    from source.Health.Patient as p
end;
go

create procedure Cache.fill_visit @start_date datetime, @end_date datetime
as
begin
    while @start_date <= @end_date
        begin
            insert into staging.Cache.Visit
            select v.visit_id,
                   v.visit_date,
                   v.diagnosis,
                   cast(v.visit_cost as decimal(15, 4)),
                   v.is_check_up,
                   p.patient_id,
                   p.national_code,
                   p.firstname,
                   p.lastname,
                   p.dob,
                   staging.Cache.convert_gender(p.gender),
                   p.phone,
                   doc.doctor_id,
                   doc.national_code,
                   doc.firstname,
                   doc.lastname,
                   staging.Cache.convert_gender(doc.gender),
                   doc.phone,
                   doc.specialization,
                   dep.department_id,
                   dep.department_name,
                   t.treatment_id,
                   t.treatment_type,
                   t.treatment_description,
                   cast(t.treatment_cost as decimal(15, 4)),
                   m.medication_id,
                   m.medication_name,
                   cast(m.dosage as decimal(12, 4)),
                   m.frequency,
                   m.frequency_unit,
                   cast(m.medication_cost as decimal(15, 4)),
                   m.prescription_date,
                   m.duration,
                   b.billing_id,
                   cast(b.total_amount as decimal(15, 4)),
                   cast(b.paid_amount as decimal(15, 4)),
                   cast(b.tax_amount as decimal(15, 4)),
                   cast(b.insurance_coverage as decimal(15, 4))
            from (select *
                  from source.Health.Visit
                  where visit_date >= @start_date
                    and visit_date < DATEADD(day, 1, @start_date)) as v
                     inner join source.Health.Patient as p on (v.patient_id = p.patient_id)
                     inner join source.Health.Doctor as doc on (v.doctor_id = doc.doctor_id)
                     inner join source.Health.Department as dep on (doc.department_id = dep.department_id)
                     left join source.Health.Treatment as t on (v.visit_id = t.visit_id)
                     left join source.Health.Medication as m on (v.visit_id = m.visit_id)
                     inner join source.Health.Billing as b on (v.visit_id = b.visit_id)

            set @start_date = DATEADD(day, 1, @start_date)
        end
end;
go

-- Fill treatment actually doesn't read from source
-- it reads from visit because visit already has the complete info
create procedure Cache.fill_treatment @start_date datetime, @end_date datetime
as
begin
    while @start_date <= @end_date
        begin
            insert into staging.Cache.Treatment
            select treatment_id,
                   visit_id,
                   treatment_type,
                   treatment_description,
                   treatment_cost,
                   department_id,
                   department_name
            from staging.Cache.Visit
            where (visit_date >= @start_date
                and visit_date < DATEADD(day, 1, @start_date))
              and treatment_id is not null


            set @start_date = DATEADD(day, 1, @start_date)
        end
end;
go

create procedure Cache.fill_medication @start_date datetime, @end_date datetime
as
begin
    while @start_date <= @end_date
        begin
            insert into staging.Cache.Medication
            select medication_id,
                   visit_id,
                   medication_name,
                   dosage,
                   frequency,
                   frequency_unit,
                   medication_cost,
                   prescription_date,
                   duration
            from staging.Cache.Visit
            where (visit_date >= @start_date
                and visit_date < DATEADD(day, 1, @start_date))
              and medication_id is not null


            set @start_date = DATEADD(day, 1, @start_date)
        end
end;
go

create procedure Cache.fill_billing @start_date datetime, @end_date datetime
as
begin
    while @start_date <= @end_date
        begin
            insert into staging.Cache.Billing
            select billing_id, visit_id, total_amount, paid_amount, tax_amount, insurance_coverage
            from staging.Cache.Visit
            where (visit_date >= @start_date
                and visit_date < DATEADD(day, 1, @start_date))


            set @start_date = DATEADD(day, 1, @start_date)
        end
end;
go

-- Just call the main to call other procedures in order
create procedure Cache.main
as
begin
    declare @start_date datetime;
    declare @end_date datetime;

    select @end_date = max(visit_date)
    from source.Health.Visit

    if exists(select * from staging.Cache.Visit)
        begin
            select @start_date = max(visit_date)
            from staging.Cache.Visit
        end
    else
        begin
            select @start_date = min(visit_date)
            from source.Health.Visit
        end

    execute staging.Cache.fill_department;
    execute staging.Cache.fill_doctor;
    execute staging.Cache.fill_patient;
    execute staging.Cache.fill_visit @start_date, @end_date;
    execute staging.Cache.fill_treatment @start_date, @end_date;
    execute staging.Cache.fill_medication @start_date, @end_date;
    execute staging.Cache.fill_billing @start_date, @end_date;
end;
go