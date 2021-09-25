<?PHP

					// --------------------------------------------------------------------------------------------------------------------------------
					// used to resize photos
					class ImgResize {
						private $originalFile = '';
						public function __construct($originalFile = '') {
							$this -> originalFile = $originalFile;
						}
						public function resize($newWidth, $targetFile) {
							if (empty($newWidth) || empty($targetFile)) {
								return false;
							}
							$src = imagecreatefromjpeg($this -> originalFile);
							list($width, $height) = getimagesize($this -> originalFile);
							$newHeight = ($height / $width) * $newWidth;
							$tmp = imagecreatetruecolor($newWidth, $newHeight);
							imagecopyresampled($tmp, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
							if (file_exists($targetFile)) {
								unlink($targetFile);
							}
							imagejpeg($tmp, $targetFile, 85); // 85 is my choice, make it between 0 � 100 for output image quality with 100 being the most luxurious
						}
					} // image resize

					// make the destination directory if it doesn't exist yet
					if (!is_dir($BasePath)){
						mkdir($BasePath, 0777, true);
					} // end: make directory if not exists

					// get dimensions of original IMG
					$size = getimagesize($_FILES['image']['tmp_name']);
					$filesize = filesize($_FILES['image']['tmp_name']);
					list($width, $height) = $size;
					$aspectRatio = $width / $height;
					// 640/480 = 1.33333 Landscape
					// 480/640 = 0.75 Portrait

					// if a thumbnail version of the file doesn't exist yet, make one
					if (!file_exists($FullFilename_Thumb)){
						// Make Thumbnail. 100w for landscape 75w for portrait 
						$work = new ImgResize($_FILES['image']['tmp_name']); // source
						$work -> resize(($aspectRatio > 1 ? 100 : 56), $FullFilename_Thumb); // destination
						$ThumbSuccessful = 1;						
					} // end: thumb photo

					// if a resized copy of the photo doesn't exist yet, make one
					if (!file_exists($FullFilename_Processed)){
						$work = new ImgResize($_FILES['image']['tmp_name']); // source
						if ($aspectRatio > 1 && $aspectRatio < 1.5){ // Landscape
							$work -> resize(800, $FullFilename_Processed); // destination
						}elseif ($aspectRatio >= 1.5){ 	// Wide Landscape / Panoramic
							$work -> resize(1000, $FullFilename_Processed); // destination
						}else{ 	// Portrait
							$work -> resize(600, $FullFilename_Processed); // destination
						}						
						$ProcessedSuccessful = 1;
					} // end: resized photo

					// if original photo doesn't exist yet, make it
					if (!file_exists($FullFilename_Original)){
						$copied = copy($_FILES['image']['tmp_name'], $FullFilename_Original);
						if ($copied) {
							$OriginalSuccessful = 1;
						}
					} // end: copy original

?>