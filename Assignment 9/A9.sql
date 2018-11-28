-- INVOICES, LINES AND PRODUCTS TO BE TESTED --
SELECT	*
FROM	lginvoice
WHERE	inv_num = 105

SELECT	*
FROM	lgline
WHERE	inv_num = 105

SELECT	*
FROM	lgproduct
WHERE	prod_sku = '1010-MIW'

-- TEST INSERT --
INSERT INTO	lgline VALUES(105, 2, '1010-MIW', 1, 21.99)	--Adds 21.99 to total from Initial total of 6.59 (should display 28.58)

SELECT	inv_num, inv_total
FROM	lginvoice
WHERE	inv_num = 105	--New total: 28.58 (MAY BE SLIGHTLY OFF DUE TO ROUNDING...)

-- TEST DELETE --
DELETE FROM	lgline
WHERE		inv_num = 105 AND line_num = 2	--Should revert the total back to 6.59

SELECT	inv_num, inv_total
FROM	lginvoice
WHERE	inv_num = 105	--Total: 6.59 (Original total!)

-- TEST UPDATE --
UPDATE	lgline
SET	line_qty = 0
WHERE	inv_num = 105 AND line_num = 1

-- TRIGGER --
ALTER TRIGGER A9
ON lgline
AFTER INSERT, DELETE, UPDATE
AS

BEGIN

	DECLARE @INV_NUM CHAR(3)
	DECLARE @NEW_QTY INT
	DECLARE @LINE_PRICE DECIMAL

	IF(EXISTS(SELECT * FROM INSERTED))
	BEGIN
		
		DECLARE INSERTED_CURSOR CURSOR FOR
		SELECT	inv_num, line_qty, line_price
		FROM	INSERTED
		ORDER BY inv_num

		OPEN	INSERTED_CURSOR
		FETCH	NEXT FROM INSERTED_CURSOR
			INTO @INV_NUM, @NEW_QTY, @LINE_PRICE
		WHILE(@@FETCH_STATUS = 0)
			BEGIN
				UPDATE	lginvoice
				SET	inv_total = inv_total + @NEW_QTY * @LINE_PRICE
				WHERE	inv_num = @INV_NUM
				FETCH	NEXT FROM INSERTED_CURSOR
					INTO @INV_NUM, @NEW_QTY, @LINE_PRICE
			END
			CLOSE INSERTED_CURSOR
			DEALLOCATE INSERTED_CURSOR
	END

	IF(EXISTS(SELECT * FROM DELETED))
	BEGIN
		
		DECLARE DELETED_CURSOR CURSOR FOR
		SELECT	inv_num, line_qty, line_price
		FROM	DELETED
		ORDER BY inv_num

		OPEN	DELETED_CURSOR
		FETCH	NEXT FROM DELETED_CURSOR
			INTO @INV_NUM, @NEW_QTY, @LINE_PRICE
		WHILE(@@FETCH_STATUS = 0)
			BEGIN
				UPDATE	lginvoice
				SET	inv_total = inv_total - @NEW_QTY * @LINE_PRICE
				WHERE	inv_num = @INV_NUM
				FETCH	NEXT FROM DELETED_CURSOR
					INTO @INV_NUM, @NEW_QTY, @LINE_PRICE
			END
			CLOSE DELETED_CURSOR
			DEALLOCATE DELETED_CURSOR
	END
END
