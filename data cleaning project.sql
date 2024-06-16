USE portfolio_project;

-- Cleaning data in SQL queries

SELECT * 
FROM portfolio_project.housing_data;

-- ---------------------------------------------------------------------------------------------

-- Standardize data format (from DateTime to just Date, we already had in Date format but..)

SELECT 
	SaleDate, CONVERT(SaleDate, DATE) AS converted
FROM housing_data;

-- Update the table, if not working try below with the alter method

UPDATE housing_data
SET SaleDate = CONVERT(SaleDate, DATETIME);

-- Alter (you would then drop the initial column if using this):

ALTER TABLE housing_data
ADD SaleDateConverted DATETIME;

UPDATE housing_data
SET SaleDateConverted = CONVERT(SaleDate, DATETIME);

ALTER TABLE housing_data
DROP COLUMN SaleDateConverted;

-- ---------------------------------------------------------------------------------------------

-- Populate property address

-- Check if some PropertyAddress data is null, then we populate the address for them

SELECT *
FROM housing_data
-- WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;

-- Here we're providing the PropertyAddress for rows that have a NULL value, using data from other rows that have the same ParcelID.
-- After the update the below shows nothing since there wownt be any PropertyAddresses with NULL values

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_data a
JOIN housing_data b 
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update the table

UPDATE housing_data a
JOIN housing_data b 
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- ---------------------------------------------------------------------------------------------

-- Breaking out Address into multiple columns (Address, City)

SELECT PropertyAddress
FROM housing_data;

SELECT
	SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) - 1) as Address,
    SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) + 1, LENGTH(PropertyAddress)) as City
FROM housing_data; 

-- Create new columns for our new values

ALTER TABLE housing_data
ADD PropertySplitAddress VARCHAR(255);

UPDATE housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) - 1);


ALTER TABLE housing_data
ADD PropertySplitCity VARCHAR(255);

UPDATE housing_data
SET PropertySplitCity =  SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) + 1, LENGTH(PropertyAddress));

-- Chack our results

SELECT *
FROM housing_data;

-- ---------------------------------------------------------------------------------------------

-- Splitting the OwnerAddress as well (address, city, state)
-- Maybe an easier way than with just SUBSTRING

SELECT OwnerAddress
FROM housing_data;

SELECT
    SUBSTRING_INDEX(OwnerAddress, ",", 1) AS Address,
	SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1) AS City,
	SUBSTRING_INDEX(OwnerAddress, ",", -1) AS State
FROM housing_data;

-- Update our table

ALTER TABLE housing_data
ADD OwnerSplitAddress VARCHAR(255);

UPDATE housing_data
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ",", 1);


ALTER TABLE housing_data
ADD OwnerSplitCity VARCHAR(255);

UPDATE housing_data
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1);


ALTER TABLE housing_data
ADD OwnerSplitState VARCHAR(255);

UPDATE housing_data
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ",", -1);


-- Check our result

SELECT *
FROM housing_data;

-- ---------------------------------------------------------------------------------------------

-- Change Y and N value to Yes and No in SoldAsVacant column (some are already Yes/No)


-- Check the unique values and their count

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
FROM housing_data
GROUP BY SoldAsVacant
ORDER BY 2 DESC;


-- Fixing

SELECT 
	SoldAsVacant,
    CASE
		WHEN SoldAsVacant = "Y" THEN "Yes"
        WHEN SoldAsVacant = "N" THEN "No"
        ELSE SoldAsVacant
	END
FROM housing_data;

-- Update our table

UPDATE housing_data
SET SoldAsVacant =
	CASE
		WHEN SoldAsVacant = "Y" THEN "Yes"
        WHEN SoldAsVacant = "N" THEN "No"
        ELSE SoldAsVacant
	END;


-- ---------------------------------------------------------------------------------------------

-- Remove duplicates

-- For future cases, do consider whether you actually want to delete any records from the database even if they are dublicates


SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID
		) as row_num
	FROM housing_data
) AS subquery;

-- From above query we get a new column called row_num with values of 1 in each row, but if there is 2, then its most likely a duplicate of the above row
-- So we'll be deleting the rows with row_num 2 (note the uniqueID is still different but other listed columns in PARTITION BY statement are the same)
-- Using the above query to delete records (note you need to state only one unique column):

DELETE FROM housing_data
WHERE UniqueID IN (
		SELECT UniqueID
		FROM (
			SELECT UniqueID,
				ROW_NUMBER() OVER (
				PARTITION BY
					ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
				ORDER BY UniqueID
				) as row_num
			FROM housing_data
	) AS subquery
    WHERE row_num > 1
);

-- Check if there are any duplicates left:

SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID
		) as row_num
	FROM housing_data
) AS subquery
WHERE row_num > 1;


-- ---------------------------------------------------------------------------------------------

-- Delete unused columns
-- Note: Don't do this for the raw data, deleting may be suitable in temporary tables/CTEs


SELECT *
FROM housing_data;


ALTER TABLE housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;

SELECT *
FROM housing_data;





















