<?php
	$url1 = "http://t66y.com/index.php?u=584544&ext=75e07";
	$UserAgent = 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; .NET CLR 3.5.21022; .NET CLR 1.0.3705; .NET CLR 1.1.4322)';  
	$curl = curl_init();    //创建一个新的CURL资源  
	curl_setopt($curl, CURLOPT_URL, $url1);  //设置URL和相应的选项  
	curl_setopt($curl, CURLOPT_HEADER, 0);  //0表示不输出Header，1表示输出  
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);  //设定是否显示头信息,1显示，0不显示。  
	//如果成功只将结果返回，不自动输出任何内容。如果失败返回FALSE  
	
	curl_setopt($curl, CURLOPT_ENCODING, '');   //设置编码格式，为空表示支持所有格式的编码  
	//header中“Accept-Encoding: ”部分的内容，支持的编码格式为："identity"，"deflate"，"gzip"。  
	  
	curl_setopt($curl, CURLOPT_USERAGENT, $UserAgent);  
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);  
	//设置这个选项为一个非零值(象 “Location: “)的头，服务器会把它当做HTTP头的一部分发送(注意这是递归的，PHP将发送形如 “Location: “的头)。  
	
	echo "Visiting URL: ".$url1."\n";
	$output = curl_exec($curl);
	curl_close($curl);  //关闭cURL资源，并释放系统资源
	
	$reg = "/\?u=[0-9]*&vcencode=[0-9]*/";
	preg_match($reg, $output, $data);
	echo "Returned Action: ", $data[0], "\n";
	
	$url2 = "http://t66y.com/index.php".$data[0];
	echo "New URL: ", $url2, "\n";
	
	$data = ['url'=>'','ext'=>'75e07','adsaction'=>'userads1010'];
	$headers = array('Content-Type: application/x-www-form-urlencoded');
	$agent ="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36";
	$curl2 = curl_init(); // 启动一个CURL会话
	curl_setopt($curl2, CURLOPT_URL, $url2); // 要访问的地址
	curl_setopt($curl2, CURLOPT_USERAGENT, $agent); // 模拟用户使用的浏览器
	curl_setopt($curl2, CURLOPT_FOLLOWLOCATION, 1); // 使用自动跳转
	curl_setopt($curl2, CURLOPT_AUTOREFERER, 1); // 自动设置Referer
	curl_setopt($curl2, CURLOPT_POST, 1); // 发送一个常规的Post请求
	curl_setopt($curl2, CURLOPT_POSTFIELDS, http_build_query($data)); // Post提交的数据包
	curl_setopt($curl2, CURLOPT_TIMEOUT, 30); // 设置超时限制防止死循环
	curl_setopt($curl2, CURLOPT_HEADER, 0); // 显示返回的Header区域内容
	curl_setopt($curl2, CURLOPT_RETURNTRANSFER, true); // 获取的信息以文件流的形式返回
	curl_setopt($curl2, CURLOPT_HTTPHEADER, $headers);
	$result = curl_exec($curl2); // 执行操作
	if (curl_errno($curl2)) {
		echo 'Error occurred with number '.curl_error($curl2).'\n';//捕抓异常
	}
	else {
		echo "New URL was successfully visited.\n";
	}
		
	curl_close($curl2); // 关闭CURL会话
?>
