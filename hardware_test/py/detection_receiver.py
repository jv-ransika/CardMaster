import socket
import json

def start_server(host, port):
    """
    Starts the TCP server to receive detected labels from the client.
    
    :param host: IP address of the server.
    :param port: Port number to listen on.
    """
    try:
        # Create a TCP socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
            # Bind the socket to the address and port
            server_socket.bind((host, port))

            # Start listening for incoming connections
            server_socket.listen(1)
            print(f"Listening for connections on {host}:{port}...")

            # Accept a connection from the client
            client_socket, client_address = server_socket.accept()
            with client_socket:
                print(f"Connection established with {client_address}")
                
                # Use a while loop to continuously check for incoming data
                while True:
                    # Receive the data
                    data = client_socket.recv(1024)  # Buffer size (1024 bytes)

                    if data:
                        # Decode and parse the received JSON data
                        detected_labels = json.loads(data.decode('utf-8'))
                        print("Received detected labels:")
                        print(detected_labels)
                    else:
                        print("No data received.")
                        
    except Exception as e:
        print(f"Error starting server: {e}")


# Host and port for the server
server_host = '0.0.0.0'  # Listen on all available network interfaces
server_port = 5006       # The port to listen on
start_server(server_host, server_port)
