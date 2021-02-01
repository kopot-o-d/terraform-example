[
	{
		"environmentFiles": [
			{
				"value": "arn:aws:s3:::binarystudio/env/api.env",
				"type": "s3"
			}
		],
		"portMappings": [
			{
				"hostPort": 80,
				"protocol": "tcp",
				"containerPort": 80
			}
		],
		"cpu": 0,
		"memoryReservation": 256,
		"image": "nginx",
		"name": "client"
	}	
]