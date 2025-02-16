use sakila;

-- 2
create view view_long_action_movies
as
	select f.film_id, f.title, f.length, c.name as category_name
    from film f
    join film_category fc on fc.film_id = f.film_id
    join category c on c.category_id = fc.category_id
    where c.name = 'Action' and f.length > 100;
    
select * from view_long_action_movies;

-- 3
create view view_texas_customers
as
	select distinct c.customer_id, c.first_name, c.last_name, ct.city
    from customer c
    join rental rt on rt.customer_id = c.customer_id
    join address ad on ad.address_id = c.address_id
    join city ct on ct.city_id = ad.city_id
    where ad.district = 'Texas';
    
select * from view_texas_customers;

-- 4
INSERT INTO staff (first_name, last_name, address_id, picture, email, active, username, password)
VALUES
('John', 'Doe', 1, NULL, 'john.doe@example.com', TRUE, 'johndoe', 'password123'),
('Jane', 'Smith', 2, NULL, 'jane.smith@example.com', TRUE, 'janesmith', 'password123');

INSERT INTO store (manager_staff_id, address_id)
VALUES
(1, 1), (2, 2);

create view view_high_value_staff
as
	select st.staff_id, st.first_name, st.last_name, sum(pm.amount) as total_amount
    from staff st
    join payment pm on pm.staff_id = st.staff_id
    group by pm.staff_id
    having sum(pm.amount) > 100;
    
select * from view_high_value_staff;

-- 5
create index idx_film_title_description on film(title, description); 

-- 6
create index idx_rental_inventory_id on rental(inventory_id);

-- 7
select title, length from view_long_action_movies
where length > 100 and title like '%War%'; 

-- 8
delimiter &&
create procedure GetRentalByInventory(in inventory_id int)
begin
	select * from rental r
    where r.inventory_id = inventory_id;
end &&
delimiter && 

call GetRentalByInventory(1);

-- 9
drop view view_long_action_movies;
drop view view_texas_customers;
drop view view_high_value_staff;
drop index idx_film_title_description on film;
drop index idx_rental_inventory_id on rental
drop procedure GetRentalByInventory;

