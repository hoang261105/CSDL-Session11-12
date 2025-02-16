-- Bài 7
create table departments(
	dept_id int primary key auto_increment,
    name varchar(100) not null,
    manager varchar(100) not null,
    budget decimal(15,2) not null
);

create table employees(
	emp_id int primary key auto_increment,
    name varchar(100) not null,
    dept_id int,
    foreign key (dept_id) references departments(dept_id),
    salary decimal(10,2) not null,
    hire_date date not null
);

create table projects1(
	project_id int primary key auto_increment,
    name varchar(100) not null,
    emp_id int,
    foreign key (emp_id) references employees(emp_id),
    start_date date not null,
    end_date date,
    status varchar(50) not null
);

-- 2
delimiter &&
create trigger trg_before_insertEmp before insert on employees
for each row
begin 
	declare dept_exists int;
    declare active_projects int;
	if NEW.salary < 500 then
		signal sqlstate '45000'
		set message_text = 'Error: Salary must be at least 500!';
	end if;
    
    select count(*) into dept_exists from departments where dept_id = NEW.dept_id;
    if dept_exists = 0 then
		signal sqlstate '45000'
        set message_text = 'Error: Department does not exist!';
	end if;
    
    select count(*) into active_projects from projects1 p
     where p.emp_id in (select emp_id from employees where dept_id = NEW.dept_id) 
     and p.status <> 'Completed';
    
    if active_projects = 0 then
		signal sqlstate '45000'
        set message_text = 'Error: All projects in this department are completed!';
	end if;
end &&
delimiter && 

drop trigger trg_before_insertEmp;

-- 3
create table project_warnings(
	warning_id int primary key auto_increment,
    project_id int,
    warning_message varchar(255)
);

create table depart_warnings(
	warning_id int primary key auto_increment,
    dept_id int,
    warning_message varchar(255)
);

delimiter &&
create trigger trg_after_updateStatus after update on projects1
for each row
begin
	declare sum_salary decimal(10,2);
    declare dept_budget decimal(15,2);
    declare project_dept_id int;
    
	if NEW.status = 'Delayed' then 
		insert into project_warnings(project_id, warning_message)
        values(NEW.project_id, 'Dự án đã bị trì hoãn');
	end if;
    
	if NEW.status = 'Completed' then
        select e.dept_id into project_dept_id
        from employees e
        where e.emp_id = NEW.emp_id
        limit 1;
        
        select sum(e.salary), d.budget into sum_salary, dept_budget from employees e
        join departments d on d.dept_id = e.dept_id
        where d.dept_id = project_dept_id
        group by d.dept_id;
        
        if sum_salary > dept_budget then
			insert into depart_warnings(dept_id, warning_message)
            values(project_dept_id, 'Budget exceeded due to high salary');
        end if;
	end if;
end &&
delimiter && 

drop trigger trg_after_updateStatus;
-- 4
create view FullOverview 
as
	select 
		e.emp_id, 
        e.name as employeeName, 
        d.name as departmentName, 
        p.name as projectname,
        p.status,
        concat(e.salary, '$') as salary,
        pw.warning_message
	from departments d
    join employees e on e.dept_id = d.dept_id
    join projects1 p on p.emp_id = e.emp_id
    join project_warnings pw on pw.project_id = p.project_id;
    
-- 5+6
INSERT INTO departments (name, manager, budget) VALUES
('IT Department', 'Alice Johnson', 4000.00),
('HR Department', 'Bob Smith', 3000.00);

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Alice', 1, 600, '2023-07-01'),
('Bob', 2, 1000, '2023-07-01'),
('Charlie', 2, 1500, '2023-07-01'),
('David', 1, 2000, '2023-07-01');

INSERT INTO projects1 (name, emp_id, start_date, end_date, status) VALUES
('Website Development', 1, '2024-01-10', '2024-06-15', 'In Progress'),
('Mobile App', 2, '2024-03-05', '2024-09-10', 'In Progress'),
('AI Research', 3, '2024-05-20', '2024-12-01', 'Delayed'),
('Cloud Migration', 4, '2024-07-01', '2024-11-30', 'Delayed');


UPDATE projects1 SET status = 'Delayed' WHERE project_id = 1;

UPDATE projects1 SET status = 'Completed', end_date = NULL WHERE project_id = 2;

UPDATE projects1 SET status = 'Completed' WHERE project_id = 3;

UPDATE projects1 SET status = 'In Progress' WHERE project_id = 4;

-- 7
select * from fullOverview;
 
-- Bài 8
-- 2
create table salary_history(
	history_id int primary key auto_increment,
    emp_id int not null,
    old_salary decimal(10,2) not null,
    new_salary decimal(10,2) not null,
    change_date datetime not null
);

-- 3
create table salary_warnings(
	warning_id int primary key auto_increment,
    emp_id int not null,
    warning_message varchar(255) not null,
    warning_date datetime not null
);

-- 4
delimiter &&
create trigger trg_after_updateSalary before update on employees
for each row
begin 
	declare salary_change decimal(10,2);
    
    insert into salary_history(emp_id, old_salary, new_salary, change_date)
    values(NEW.emp_id, OLD.salary, NEW.salary, now());
    
	if NEW.salary < OLD.salary * 0.7 then
		insert into salary_warnings(emp_id, warning_message, warning_date)
        values(NEW.emp_id, 'Salary decreased by more than 30%', now());
	end if;
    
    if NEW.salary > OLD.salary * 1.5 then
		set salary_change = OLD.salary * 1.5;
        
        insert into salary_warnings(emp_id, warning_message, warning_date)
        values(NEW.emp_id, 'Salary increased above allowed threshold (adjusted to 150% of previous salary)', now());
    end if;
end &&
delimiter && 

drop trigger trg_after_updateSalary;

-- 5
delimiter &&
create trigger trg_after_insertProjects after insert on projects1
for each row
begin 
	declare count_projects int;
    
    select count(*) into count_projects from projects1 
    where status = 'In Progress' and emp_id = NEW.emp_id;
    
    if count_projects > 3 then
		signal sqlstate '45000'
        set message_text = 'Employee cannot be assigned to more than 3 active projects';
    end if;
    
    if NEW.status = 'In Progress' then
		if NEW.start_date > curdate() then
			signal sqlstate '45000'
			set message_text = 'Start date must be less than current date!';
        end if;
    end if;
end &&
delimiter && 

drop trigger trg_after_insertProjects;
-- 6
create view PerformanceOverview
as
	select 
		p.project_id, 
        p.name as projectName, 
        count(p.emp_id) as employee_count, 
        timestampdiff(day, p.end_date, p.start_date) as total_days,
        p.status
	from projects1 p;
    
-- 7
update employees
set salary = salary * 0.5
where emp_id = 1; 

update employees
set salary = salary * 2
where emp_id = 2;

-- 8
-- Trường hợp 1: Nhân viên tham gia hơn 3 dự án

INSERT INTO projects1 (name, emp_id, start_date, status) 

VALUES ('New Project 1', 1, CURDATE(), 'In Progress');

INSERT INTO projects1 (name, emp_id, start_date, status) 

VALUES ('New Project 2', 1, CURDATE(), 'In Progress');

INSERT INTO projects1 (name, emp_id, start_date, status) 

VALUES ('New Project 3', 1, CURDATE(), 'In Progress');

INSERT INTO projects1 (name, emp_id, start_date, status) 

VALUES ('New Project 4', 1, CURDATE(), 'In Progress');  

INSERT INTO projects1 (name, emp_id, start_date, status) 

VALUES ('Future Project', 2, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'In Progress');

-- 8
select * from PerformanceOverview; 