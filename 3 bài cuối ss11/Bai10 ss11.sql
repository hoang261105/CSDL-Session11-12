use sakila;

-- 2
create unique index idx_unique_email on customer(email);

INSERT INTO customer (store_id, first_name, last_name, email, address_id, active, create_date)
VALUES (1, 'Jane', 'Doe', 'johndoe@example.com', 6, 1, NOW());

-- 3
delimiter &&
create procedure CheckCustomerEmail(in email_input varchar(100), out exists_flag bit)
begin 
    select count(*) into exists_flag from customer
    where email = email_input;
    
    if(exists_flag > 0) then
        signal sqlstate '45000'
        set message_text = 'Email đã tồn tại';
	end if;
end &&
delimiter && 

set @exists_flag = 0;
call CheckCustomerEmail('MARY.SMITH@sakilacustomer.org', @exists_flag);
SELECT @exists_flag;

-- 4
create index idx_rental_customer_id on rental(customer_id);

-- 5
create view view_active_customer_rentals
as 
	select 
		c.customer_id, 
        concat(c.last_name, ' ', c.first_name) as customerName, 
        (case
			when rt.rental_date is not null then 'Returned'
            else 'Not returned'
		end) as status, 
        rt.rental_date
    from customer c
    join rental rt on rt.customer_id = c.customer_id
    where c.active = 1 
    and rt.rental_date >= '2003-01-01' 
    and (rt.return_date is null or rt.return_date >= CURDATE() - INTERVAL 30 DAY);
    
-- 6
create index idx_payment_customer_id on customer(customer_id); 

-- 7
create view view_customer_payments
as
	select c.customer_id, concat(c.last_name, ' ', c.first_name) as fullName, sum(p.amount) as total_payment
    from customer c
    join payment p on p.customer_id = c.customer_id
    where p.payment_date >= '2003-01-01'
    group by p.customer_id
    having sum(p.amount) > 100;
    
select * from view_customer_payments;

-- 8
delimiter &&
create procedure GetCustomerPaymentsByAmount(in min_amount int, in date_from date)
begin
	select * from view_customer_payments vcp
    join payment p on p.customer_id = vcp.customer_id
    where vcp.total_payment >= min_amount and p.payment_date >= date_from;
end &&
delimiter && 

call GetCustomerPaymentsByAmount(80, '2005-05-01');

-- 9
drop view view_active_customer_rentals;
drop view view_customer_payments;
drop index idx_unique_email on customer;
drop index idx_rental_customer_id on rental;
drop index idx_payment_customer_id on customer;
drop procedure CheckCustomerEmail;
drop procedure GetCustomerPaymentsByAmount;