# Use a lightweight Python base image
FROM python:3.9-slim

# Set working directory inside the container
WORKDIR /app

# Install Flask directly (no requirements.txt for simplicity in this lab)
RUN pip install flask

# Copy the application code
COPY main.py .

# Expose port 5000
EXPOSE 5000

# Command to run the application
CMD ["python", "main.py"]