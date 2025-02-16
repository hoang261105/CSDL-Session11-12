create table deleted_orders(
	delete_id int primary key auto_increment,
    order_id int not null,
    customer_name varchar(100) not null,
    product varchar(100) not null,
    order_date date not null,
    deleted_at datetime not null
);

-- 3
delimiter &&
create trigger trg_after_delete after delete on orders
for each row
begin
	insert into deleted_orders(order_id, customer_name, product, order_date, deleted_at)
	values(OLD.order_id, OLD.customer_name, OLD.product, OLD.order_date, now());
end &&
delimiter && 

-- 4 
delete from orders
where order_id = 4;

delete from orders
where order_id = 5;

-- 5
drop trigger trg_after_delete; 