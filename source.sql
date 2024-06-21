-- Just create a schema to unset the schema from dbo
use source
go
drop schema if exists Health;

use source
go
create schema Health;

-- drop tables
drop table if exists source.Health.Billing
drop table if exists source.Health.Medication
drop table if exists source.Health.Treatment
drop table if exists source.Health.Visit
drop table if exists source.Health.Patient
drop table if exists source.Health.Doctor
drop table if exists source.Health.Department

-- create needed tables
create table source.Health.Department
(
    department_id   int identity (1, 1) primary key,
    department_name nvarchar(255) not null,
)

create table source.Health.Doctor
(
    doctor_id      int identity (1, 1) primary key,
    firstname      nvarchar(255) not null,
    lastname       nvarchar(255) not null,
    phone          nvarchar(10)  not null,
    specialization nvarchar(100) not null,
    department_id  int           not null,

    foreign key (department_id) references source.Health.Department (department_id),
)


create table source.Health.Patient
(
    patient_id   int identity (1, 1) primary key,
    firstname    nvarchar(255) not null,
    lastname     nvarchar(255) not null,
    dob          Date          not null, -- date of birthday
    gender       char(1)       not null, -- 0 for woman 1 for man
    address      nvarchar(max) not null,
    phone        nvarchar(10)  not null,
)

create table source.Health.Visit
(
    visit_id   int identity (1, 1) primary key,
    patient_id int           not null,
    doctor_id  int           not null,
    visit_date DATETIME      not null,
    diagnosis  nvarchar(max) not null,

    foreign key (patient_id) references source.Health.Patient (patient_id),
    foreign key (doctor_id) references source.Health.Doctor (doctor_id),
)

create table source.Health.Treatment
(
    treatment_id          int identity (1, 1) primary key,
    visit_id              int           not null,
    treatment_type        nvarchar(50)  not null,
    treatment_description nvarchar(max) not null,
    department_id         int           not null,

    foreign key (visit_id) references source.Health.Visit (visit_id),
    foreign key (department_id) references source.Health.Department (department_id),
)

create table source.Health.Medication
(
    medication_id     int identity (1, 1) primary key,
    visit_id          int            not null,
    medication_name   nvarchar(255)  not null,
    dosage            decimal(8, 2)  not null,
    frequency         int            not null,
    frequency_unit    nvarchar(50)   not null check (frequency_unit in ('minute', 'hour', 'day', 'week', 'month')),
    cost              decimal(11, 2) not null,
    prescription_date date           not null,
    duration          int            not null, -- unit is day

    foreign key (visit_id) references source.Health.Visit (visit_id),
)

create table source.Health.Billing
(
    billing_id         int identity (1, 1) primary key,
    visit_id           int            not null,
    total_amount       decimal(11, 2) not null,
    paid_amount        decimal(11, 2) not null,
    tax_amount         decimal(11, 2) not null,
    insurance_coverage decimal(11, 2) not null,

    foreign key (visit_id) references source.Health.Visit (visit_id),
)
