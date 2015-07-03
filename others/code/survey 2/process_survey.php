<?php
$dbhost = 'YOUR_SERVER';
$dbuser = 'YOUR_USERNAME';
$dbpass = 'YOUR_PASSWORD';
$dbname = 'YOUR_DATABASE_NAME';

$conn = mysql_connect($dbhost, $dbuser, $dbpass) or die ('Error connecting to mysql');
mysql_select_db($dbname);

$db_check = 'OK';
$return_arr = array();


if (!$conn)
  {
  $db_check = 'fail';
  }

if ($db_check === 'OK'){
	$insert_sql = mysql_query("INSERT INTO survey (color,sport) VALUES ('".$_POST['radio_color']."','".$_POST['radio_sport']."')"); 
	if (!$insert_sql) {
		$db_check = 'fail';
	}
}

if ($db_check === 'OK'){
	$fetch = mysql_query("SELECT * FROM v_totals"); 
	
	/* Retrieve and display the results of the query. */
	$row = mysql_fetch_array($fetch);
	
	$totalPink = $row[0];
	$return_arr["totalPink"] = $totalPink;
	$perPink = round($row[0]/($row[0]+$row[1]),2)*100;
	$return_arr["perPink"] = $perPink;
	
	$totalBlue = $row[1];
	$return_arr["totalBlue"] = $totalBlue;
	$perBlue = round($row[1]/($row[0]+$row[1]),2)*100;
	$return_arr["perBlue"] = $perBlue;
	
	$totalFutbol = $row[2];
	$return_arr["totalFutbol"] = $totalFutbol;
	$perFutbol = round($row[2]/($row[2]+$row[3]),2)*100;
	$return_arr["perFutbol"] = $perFutbol;
	
	$totalSoccer = $row[3];
	$return_arr["totalSoccer"] = $totalSoccer;
	$perSoccer = round($row[3]/($row[2]+$row[3]),2)*100;
	$return_arr["perSoccer"] = $perSoccer;
	
	$totalRes = $row[4];
	$return_arr["totalRes"] = $totalRes;
}
else {
	$db_check = 'fail';
}
/* Free connection resources. */
mysql_close($conn);

$return_arr["db_check"] = $db_check;

echo json_encode($return_arr);

?>