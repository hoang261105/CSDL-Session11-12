use chinook;

-- 2
create view View_High_Value_Customers
as
	select c.customerId, concat(c.lastName, ' ', c.firstName) as fullName, c.email, sum(iv.total) as total_spending
    from customer c
    join invoice iv on iv.customerId = c.customerId
    where iv.invoiceDate > '2010-01-01 00:00:00' and c.country <> 'Brazil'
    group by iv.customerId
    having sum(iv.total) > 200;
    
select * from View_High_Value_Customers;

-- 3
create view View_Popular_Tracks
as
	select tr.trackId, tr.name as trackName, count(ivl.quantity) as total_sales
    from track tr
    join invoiceline ivl on ivl.trackId = tr.trackId
    where ivl.unitPrice > 1
    group by ivl.trackId
    having count(ivl.quantity) > 15;
    
select * from View_Popular_Tracks;

-- 4
create index idx_Customer_Country on customer(country);
 
select * from customer 
where country = 'Canada';

explain select * from customer 
where country = 'Canada';

-- 5
create index idx_Track_Name_FT on track(name);

ALTER TABLE Track 
ADD FULLTEXT INDEX idx_Track_Name_FT (Name);

select * from track 
where match(name) against('Love' in natural language mode);

explain select * from track 
where match(name) against('Love' in natural language mode);

-- 6
select vhc.customerId, vhc.fullName, vhc.email, vhc.total_spending
from view_high_value_customers vhc
join customer c on c.customerId = vhc.customerId
join invoice iv on iv.customerId = c.customerId
where c.country = 'Canada'
group by iv.customerId;

explain select vhc.customerId, vhc.fullName, vhc.email, vhc.total_spending
from view_high_value_customers vhc
join customer c on c.customerId = vhc.customerId
join invoice iv on iv.customerId = c.customerId
where c.country = 'Canada'
group by iv.customerId;

-- 7
select * from view_popular_tracks vpt
join track tr on tr.trackId = vpt.trackId
where vpt.total_sales > 15 and vpt.trackName like '%Love%';

-- 8
delimiter &&
create procedure GetHighValueCustomersByCountry(in p_Country char(10))
begin
	select vhc.customerId, vhc.fullName, vhc.email, vhc.total_spending from view_high_value_customers vhc
    join customer c on c.customerId = vhc.customerId
    where c.country = p_Country;
end &&
delimiter &&

call GetHighValueCustomersByCountry('VietNam');

-- 9
delimiter &&
create procedure UpdateCustomerSpending(in p_customerId int, in p_amount decimal)
begin
	update invoice
    set total = total + p_amount
    where customerId = p_customerId;
end &&
delimiter && 

CALL UpdateCustomerSpending(5, 50.00);

SELECT * FROM View_High_Value_Customers WHERE CustomerId = 5;

-- 10
drop view View_High_Value_Customers;
drop view View_Popular_Tracks;
drop index idx_Customer_Country on customer;
drop index idx_Track_Name_FT on track;
drop procedure GetHighValueCustomersByCountry;
drop procedure UpdateCustomerSpending;