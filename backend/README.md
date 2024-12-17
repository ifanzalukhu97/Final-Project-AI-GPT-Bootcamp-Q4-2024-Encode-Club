**Set Up Backend Server**
   ```bash
   cd backend
   
    # Create virtual environment
    python -m venv .venv
   
    # Activate virtual environment
    # For macOS/Linux:
    source .venv/bin/activate
   
    # For Windows:
    .\venv\Scripts\activate
    
    # Install dependencies
    pip install -r requirements.txt
    
    # Start the server
    python -m clip_server config.yml
   ```



**Verify Server Status** 

Visit http://0.0.0.0:51000/status in your browser.
   ```bash
   curl --location 'http://0.0.0.0:51000/status'
   ```


**Classification**

Example Request Payload if using an image from URL
   ```bash
   curl --location 'http://0.0.0.0:51000/post' \
    --header 'Content-Type: application/json' \
    --data '{
        "data": [
            {
                "uri": "https://images.pexels.com/photos/26384260/pexels-photo-26384260/free-photo-of-kacamata-hitam-laki-laki-pria-lelaki.jpeg",
                "matches": [
                    {
                        "text": "A photo or selfie in front of the customer’s location or store"
                    },
                    {
                        "text": "A photo of the distributor’s product display as well as competitors’ products at the customer’s location"
                    }
                ]
            }
        ],
        "execEndpoint": "/rank"
    }'
   ```


Example Request Payload if using an image from local storage or base64
```bash
   curl --location 'http://0.0.0.0:51000/post' \
    --header 'Content-Type: application/json' \
    --data '{
        "data": [
            {
                "uri": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgEASABIAAD/....",
                "matches": [
                    {
                        "text": "A photo or selfie in front of the customer’s location or store"
                    },
                    {
                        "text": "A photo of the distributor’s product display as well as competitors’ products at the customer’s location"
                    }
                ]
            }
        ],
        "execEndpoint": "/rank"
    }'
   ```