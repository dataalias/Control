<?PHP

					// EXIF DATA ------------------------------------------------------------------------------------
					// look for an original date & time on the pic
					$exif = exif_read_data($FullFilename_Original, 0, true);
					foreach ($exif as $key => $section) {
						foreach ($section as $name => $val) {
						if ($name == "DateTimeOriginal"){ $originalDateTime = $val; }
						if ($name == "Model"){ $originalModel = $val; }
						if ($name == "Height"){ $originalHeight = $val; }
						if ($name == "Width"){ $originalWidth = $val; }
						if ($name == "FileSize"){ $originalFileSize = $val; }
						}
					}
					/*
					// testing
					echo "<br>Original DateTime: ".$originalDateTime;
					echo "<br>Original Model: ".$originalModel;
					echo "<br>Original Height: ".$originalHeight;
					echo "<br>Original Width: ".$originalWidth;
					echo "<br>Original FileSize: ".$originalFileSize;
					echo "<br>";
					*/

					if (isset($originalDateTime)){
						// fix exif fields on photos that come from facebook
						if ($originalDateTime == '*'){
							$originalDateTime = '';
						}
					} // end: Date/Time
					if (isset($originalModel)){
						if ($originalModel == '*'){
							$originalModel = '';
						}
					} // end: Model
					if ($originalHeight == '*'){
						$originalHeight = '';
					} // end: Height
					if ($originalWidth == '*'){
						$originalWidth = '';
					} // end: Width
					if ($originalFileSize == '*'){
						$originalFileSize = '';
					} // end: File Size
					
					// fix exif fields on photos that were rotated
					if (isset($originalDateTime)){
						if (substr($originalDateTime, 0, 7) == 'CREATOR'){
							$originalDateTime = '';
						}
					} // end: Date/Time
					if (isset($originalModel)){
						if (substr($originalModel, 0, 7) == 'CREATOR'){
							$originalModel = '';
						}
					} // end: Model
					if (substr($originalHeight, 0, 7) == 'CREATOR'){
						$originalHeight = '';
					} // end: Height
					if (substr($originalWidth, 0, 7) == 'CREATOR'){
						$originalWidth = '';
					}		
					if (substr($originalFileSize, 0, 7) == 'CREATOR'){
						$originalFileSize = '';
					} // end: File Size	
					
					// Update DB with exif info
					if (isset($_GET['cid']) && isset($_GET['siid'])){ // Store Item
						$tsql_updateExif1 = "UPDATE res.DimStoreItemPhoto SET 
						Original_DtmString=?, 
						Original_Model=?, 
						Original_Height=?, 
						Original_Width=?, 
						Original_FileSize=?
						WHERE DimStoreItemPhotoID=?";
					}
					if (isset($_GET['cid']) && isset($_GET['rid'])){ // Rental Item
						$tsql_updateExif1 = "UPDATE res.DimRentalItemPhoto SET 
						Original_DtmString=?, 
						Original_Model=?, 
						Original_Height=?, 
						Original_Width=?, 
						Original_FileSize=?
						WHERE DimRentalItemPhotoID=?";
					}
					if (isset($_GET['cid']) && !isset($_GET['caid']) && !isset($_GET['sid'])){ // 
						$tsql_updateExif1 = "UPDATE dbo.DimPhoto SET 
						Original_DtmString=?, 
						Original_Model=?, 
						Original_Height=?, 
						Original_Width=?, 
						Original_FileSize=?
						WHERE DimPhotoID=?";
					}
					if (isset($_GET['cid']) && isset($_GET['caid']) && !isset($_GET['sid'])){ //  Area
						$tsql_updateExif1 = "UPDATE dbo.DimAreaPhoto SET 
						Original_DtmString=?, 
						Original_Model=?, 
						Original_Height=?, 
						Original_Width=?, 
						Original_FileSize=?
						WHERE DimAreaPhotoID=?";
					}
//					if (isset($_GET['cid']) && isset($_GET['caid']) && isset($_GET['sid'])){ // 
					if (isset($_GET['cid']) && isset($_GET['sid'])){ // 
						$tsql_updateExif1 = "UPDATE dbo.DimPhoto SET 
						Original_DtmString=?, 
						Original_Model=?, 
						Original_Height=?, 
						Original_Width=?, 
						Original_FileSize=?
						WHERE DimPhotoID=?";
					}

					$params_updateExif1 = array(
						(isset($originalDateTime) && $originalDateTime <> '' ? $originalDateTime : NULL)
						,(isset($originalModel) && $originalModel <> '' ? $originalModel : NULL)
						,($originalHeight ? $originalHeight : NULL)
						,($originalWidth ? $originalWidth : NULL)
						,($originalFileSize ? $originalFileSize : NULL)
						,$row_getPhotoID['PhotoID']);
					$stmt_updateExif1 = sqlsrv_query($conn, $tsql_updateExif1, $params_updateExif1);

					if (isset($originalDateTime)){					
						// try to add date and datetime values from the string
						if (isset($_GET['cid']) && isset($_GET['siid'])){ // Store Item
							$tsql_updateExif2 = "UPDATE res.DimStoreItemPhoto SET 
								Original_Date = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') as date))
								,Original_Dtm = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') + ' ' + substring(Original_DtmString, 12,20) as datetime))
								WHERE DimStoreItemPhotoID = ?
								and Original_DtmString IS NOT NULL
								and Original_Date IS NULL";
						}
						if (isset($_GET['cid']) && isset($_GET['rid'])){ // Rental Item
							$tsql_updateExif2 = "UPDATE res.DimRentalItemPhoto SET 
								Original_Date = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') as date))
								,Original_Dtm = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') + ' ' + substring(Original_DtmString, 12,20) as datetime))
								WHERE DimRentalItemPhotoID = ?
								and Original_DtmString IS NOT NULL
								and Original_Date IS NULL";
						}
						if (isset($_GET['cid']) && !isset($_GET['caid']) && !isset($_GET['sid'])){ // 
							$tsql_updateExif2 = "UPDATE dbo.DimPhoto SET 
								Original_Date = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') as date))
								,Original_Dtm = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') + ' ' + substring(Original_DtmString, 12,20) as datetime))
								WHERE DimPhotoID = ?
								and Original_DtmString IS NOT NULL
								and Original_Date IS NULL";
						}
						if (isset($_GET['cid']) && isset($_GET['caid']) && !isset($_GET['sid'])){ //  Area
							$tsql_updateExif2 = "UPDATE dbo.DimAreaPhoto SET 
								Original_Date = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') as date))
								,Original_Dtm = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') + ' ' + substring(Original_DtmString, 12,20) as datetime))
								WHERE DimAreaPhotoID = ?
								and Original_DtmString IS NOT NULL
								and Original_Date IS NULL";
						}
//						if (isset($_GET['cid']) && isset($_GET['caid']) && isset($_GET['sid'])){ // 
						if (isset($_GET['cid']) && isset($_GET['sid'])){ // 
							$tsql_updateExif2 = "UPDATE dbo.DimPhoto SET 
								Original_Date = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') as date))
								,Original_Dtm = (cast(replace(substring(Original_DtmString, 1, 10), ':', '-') + ' ' + substring(Original_DtmString, 12,20) as datetime))
								WHERE DimPhotoID = ?
								and Original_DtmString IS NOT NULL
								and Original_Date IS NULL";
						}

						$params_updateExif2 = array($row_getPhotoID['PhotoID']);
						$stmt_updateExif2 = sqlsrv_query($conn, $tsql_updateExif2, $params_updateExif2);
					} // end: chedk if there is a date/time

?>