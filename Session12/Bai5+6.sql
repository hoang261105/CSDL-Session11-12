-- Bài 5 
CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    budget DECIMAL(15, 2) NOT NULL,
    total_salary DECIMAL(15, 2) DEFAULT 0
);

CREATE TABLE workers (
    worker_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT,
    salary DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- 2
INSERT INTO projects (name, budget) VALUES

('Bridge Construction', 10000.00),

('Road Expansion', 15000.00),

('Office Renovation', 8000.00); 

-- 3
delimiter &&
create trigger trg_after_insertWorker after insert on workers
for each row
begin
    update projects
    set total_salary = total_salary + NEW.salary
    where project_id = NEW.project_id;
end &&
delimiter && 

delimiter &&
create trigger trg_after_deleteWorker after delete on workers
for each row
begin
    update projects
    set total_salary = total_salary - OLD.salary
    where project_id = OLD.project_id;
end &&
delimiter && 

-- 4
INSERT INTO workers (name, project_id, salary) VALUES

('John', 1, 2500.00),

('Alice', 1, 3000.00),

('Bob', 2, 2000.00),

('Eve', 2, 3500.00),

('Charlie', 3, 1500.00); 

-- 5
delete from workers
where worker_id = 1; 

-- Bài 6
-- 2
create table budget_warnings(
	warning_id int primary key auto_increment,
    project_id int not null,
    warning_message varchar(255) not null
);

-- 3
delimiter &&
create trigger trg_after_updateProject after update on projects
for each row
begin
	if NEW.total_salary > NEW.budget then
		if not exists(
			select 1 from budget_warnings
            where project_id = NEW.project_id
            and warning_message = 'Budget exceeded due to high salary'
        ) then
			insert into budget_warnings(project_id, warning_message)
			values(NEW.project_id, 'Budget exceeded due to high salary');
		end if;
    end if;
end &&
delimiter && 

drop trigger trg_after_updateProject;

-- 4
create view ProjectOverview
as
	select p.project_id, p.name, p.budget, p.total_salary, bw.warning_message
    from projects p 
    join budget_warnings bw on bw.project_id = p.project_id;

-- 5
INSERT INTO workers (name, project_id, salary) VALUES
('Michael', 1, 6000.00),
('Sarah', 2, 10000.00),
('David', 3, 1000.00); 

-- 6
select * from budget_warnings;
select * from ProjectOverview; 