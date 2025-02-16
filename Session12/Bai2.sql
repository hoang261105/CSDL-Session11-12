set sql_safe_updates = 0;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    order_date DATE NOT NULL
);

create table price_changes(
	change_id int primary key auto_increment,
    product varchar(100) not null,
    old_price decimal(10,2) not null,
    new_price decimal(10,2) not null
);

-- 3
delimiter &&
create trigger trg_after_update after update on orders
for each row
begin
	if OLD.price <> NEW.price then
		insert into price_changes(product, old_price, new_price)
        values(OLD.product, OLD.price, NEW.price);
    end if;
end &&
delimiter && 

INSERT INTO orders (customer_name, product, quantity, price, order_date)
VALUES 
    ('Huyền', 'Laptop', 100, 1200.00, '2024-02-10'),
    ('Anh', 'Smartphone', 50, 700.00, '2024-02-12');

-- 3 
update orders
set price = 1400
where product = 'Laptop';

update orders
set price = 800
where product = 'Smartphone';

-- 4
drop trigger trg_after_update; 