from dotenv import load_dotenv
load_dotenv()

from main import lambda_handler

test_event = {
    "mock_listings": [
        {
            "lot_id": "78291044",
            "year": 2021,
            "make": "Honda",
            "model": "Civic Hatchback EX",
            "condition": "Run & Drive",
            "primary_damage": "Rear End",
            "secondary_damage": "Minor Dent/Scratches",
            "title_type": "Salvage Title",
            "price": 8400,
            "odometer": 38200,
            "location": "Baltimore, MD",
            "listing_url": "https://www.copart.com",
            "image_url": "https://images.unsplash.com/photo-1590362891988-f77804702088?w=800"
        },
        {
            "lot_id": "89301294",
            "year": 2019,
            "make": "Mazda",
            "model": "6 Grand Touring",
            "condition": "Enhanced",
            "primary_damage": "Flood",  # Should be rejected
            "secondary_damage": "None",
            "title_type": "Clean",
            "price": 11000,
            "odometer": 45000,
            "location": "Washington, DC",
            "listing_url": "https://www.copart.com",
            "image_url": ""
        }
    ]
}

if __name__ == "__main__":
    # Note: DynamoDB calls will need AWS credentials configured (aws configure)
    # or you can temporarily comment out DynamoDB calls to test just the filter & Discord webhook.
    result = lambda_handler(test_event, None)
    print(result)