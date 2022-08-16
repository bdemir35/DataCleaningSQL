-- This project includes all cleaning process step by step from raw data to cleaned data.


-- First of all exploring the dataset

-- Nashville Housing dataset includes 19 columns with 56477 observations.
-- You can find this open source dataset and licence in this link https://data.nashville.gov/browse?limitTo=datasets&q=housing&sortBy=relevance
-- This project only shows how to use SQL queries in data cleaning process.
-- Every changes have been done just for  making a useable format and converting data to readable format.
-- This project not related to another project 

SELECT *
FROM [Portfolio Project].dbo.NashvilleHousing


-- Converting data types required format

SELECT SaleDate    -- SaleDate column has date-time data type , so we need to convert it to date format
FROM NashvilleHousing


ALTER TABLE Nashvillehousing  -- Adding new column SaleDateConverted to our dataset
ADD SaleDateConverted date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date,SaleDate) -- Assigining SaleDate column values as a date to our new column SaleDateConverted
											   -- The current format is (YYYY/MM/DD)


--------------------------------------------------------------------------------------------------------------------------

SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress is NULL -- There are some NULL values in the PropertyAddress column

-- If we join table itself and then match the ParcelId's and we can find the missing PropertyAddress values

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing as a
	JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL	 

-- Now, we need to create new column to assign addresses


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
	JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-- Filling all NULL values in PropertyAddress column with the correct addresses.

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
	JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

 -- Breaking down the PropertyAddress column into individual columns (Address, City, State)

SELECT Propertyaddress  -- PropertyAddress column has a ',' delimeter so we can separate from there
FROM NashvilleHousing


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,(CHARINDEX(',',PropertyAddress)+1),LEN(PropertyAddress)) as City
FROM NashvilleHousing

-- Adding new columns as PropertySplitAddress and PropertySplitCity

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,(CHARINDEX(',',PropertyAddress)+1),LEN(PropertyAddress))


-- The same problem is in the OwnerAddress column

SELECT OwnerAddress
FROM NashvilleHousing

-- We are going to use PARSENAME function to split these values into 3 different column easily instead of using substring here
-- PARSENAME function is only useful when we have '.' , so we need to replace this ',' into '.'

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousing

-- Adding new columns as OwnerSplitAddress, OwnerSplitCity, OwnerSplitState

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


--------------------------------------------------------------------------------------------------------------------------

-- SoldasVacant column has different values like 'Yes', 'No', 'Y' and 'N'

SELECT DISTINCT(soldasvacant), COUNT(SoldasVacant) as Count
FROM NashvilleHousing
GROUP BY soldasvacant
ORDER BY Count



-- To make them consistent , change 'Y' to 'Yes' and 'N' to 'No'

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM NashvilleHousing


-- Updating our table with new assigned values like 'Yes' and 'No'

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


-- Checking our new calculation again 

SELECT DISTINCT(soldasvacant), COUNT(SoldasVacant) as Count
FROM NashvilleHousing
GROUP BY soldasvacant
ORDER BY Count

--------------------------------------------------------------------------------------------------------------------------

-- Checking Duplicates and removing them

-- Where are going to check row numbers and then partition them over ParcelID, SaleDate, SalePrice and LegalReference, this lead to us if duplicated values occurs in each row
-- the RowNumber column will show the value greater than 1 which means the whole row duplicated the row before itself

WITH RowNumberCTE AS(
SELECT *,
		ROW_NUMBER() OVER( 
		PARTITION BY ParcelID,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY
					 UniqueID) as RowNumber
FROM NashvilleHousing)
SELECT *
FROM RowNumberCTE
WHERE RowNumber >1

--There are 104 duplicated rows in the dataset

-- Let's Remove them

WITH RowNumberCTE AS(
SELECT *,
		ROW_NUMBER() OVER( 
		PARTITION BY ParcelID,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY
					 UniqueID) as RowNumber
FROM NashvilleHousing)
DELETE
FROM RowNumberCTE
WHERE RowNumber >1



--------------------------------------------------------------------------------------------------------------------------


-- Finally we are going to remove unused columns in the dataset


ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress


SELECT *
FROM [Portfolio Project].dbo.NashvilleHousing


