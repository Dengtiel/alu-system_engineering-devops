# Web Stack Debugging #3 - WordPress 500 Error Fix

## Project Description
This project involves debugging and fixing a 500 Internal Server Error in a WordPress installation running on a LAMP stack (Linux, Apache, MySQL, PHP). The solution uses `strace` for debugging and Puppet for automation of the fix.

## Debugging Process

### Step 1: Identify the Issue
1. Check Apache processes:
   ```bash
   ps aux | grep apache
