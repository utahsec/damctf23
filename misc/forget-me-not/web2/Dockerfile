# Use an official Python runtime as an image
FROM python:3.6

# The EXPOSE instruction indicates the ports on which a container # # will listen for connections
EXPOSE 5050

# Sets the working directory for following COPY and CMD instructions
# Notice we haven’t created a directory by this name - this
# instruction creates a directory with this name if it doesn’t exist
WORKDIR /app

# Install any needed packages specified in requirements.txt
COPY requirements.txt /app/
RUN pip install -r requirements.txt

COPY *.py /app/
RUN chmod +x app.py
COPY static/ /app/static/
COPY templates/ /app/templates/

# Run app.py when the container launches
#ENV FLASK_APP=app.py

CMD ["gunicorn", "-w2", "--bind", "0.0.0.0:5050", "wsgi:app"]

