<?php
	$url1 = "https://t66y.com/index.php?u=584544&ext=75e07"; 
	$agent ="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36";	
	$curl = curl_init();
	curl_setopt($curl, CURLOPT_URL, $url1);
	curl_setopt($curl, CURLOPT_HEADER, 0); 
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);  
	curl_setopt($curl, CURLOPT_ENCODING, '');  
	curl_setopt($curl, CURLOPT_USERAGENT, $agent);  
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);  
	
	echo "Visiting URL: ".$url1."\n";
	$output = curl_exec($curl);

	curl_close($curl);
	
	$reg = "/\?u=[0-9]*&vcencode=[0-9]*/";
	preg_match($reg, $output, $data);
	echo "Returned Action: ", $data[0], "\n";
	
	$url2 = "https://t66y.com/index.php".$data[0];
	echo "New URL: ", $url2, "\n";

	sleep(5);

	$data = ['url'=>'','ext'=>'75e07','adsaction'=>'userads1010'];
	$headers = array('Content-Type: application/x-www-form-urlencoded');
	
	$curl2 = curl_init();
	curl_setopt($curl2, CURLOPT_URL, $url2);
	curl_setopt($curl2, CURLOPT_USERAGENT, $agent);
	curl_setopt($curl2, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt($curl2, CURLOPT_AUTOREFERER, 1);
	curl_setopt($curl2, CURLOPT_POST, 1);
	curl_setopt($curl2, CURLOPT_POSTFIELDS, http_build_query($data));
	curl_setopt($curl2, CURLOPT_TIMEOUT, 30);
	curl_setopt($curl2, CURLOPT_HEADER, 0);
	curl_setopt($curl2, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($curl2, CURLOPT_HTTPHEADER, $headers);
	$result = curl_exec($curl2);
	if (curl_errno($curl2)) {
		echo 'Error occurred with number '.curl_error($curl2).'\n';
	}
	else {
		echo "New URL was successfully visited.\n";
	}
		
	curl_close($curl2);
?>
