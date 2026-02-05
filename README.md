# Moodle

<p align="center"><a href="https://moodle.org" target="_blank" title="Moodle Website">
  <img src="https://raw.githubusercontent.com/moodle/moodle/main/.github/moodlelogo.svg" alt="The Moodle Logo">
</a></p>

[Moodle][1] is the World's Open Source Learning Platform, widely used around the world by countless universities, schools, companies, and all manner of organisations and individuals.

Moodle is designed to allow educators, administrators and learners to create personalised learning environments with a single robust, secure and integrated system.

## Documentation

- Read our [User documentation][3]
- Discover our [developer documentation][5]
- Take a look at our [demo site][4]

## Community

[moodle.org][1] is the central hub for the Moodle Community, with spaces for educators, administrators and developers to meet and work together.

You may also be interested in:

- attending a [Moodle Moot][6]
- our regular series of [developer meetings][7]
- the [Moodle User Association][8]

## Installation and hosting

Moodle is Free, and Open Source software. You can easily [download Moodle][9] and run it on your own web server, however you may prefer to work with one of our experienced [Moodle Partners][10].

Moodle also offers hosting through both [MoodleCloud][11], and our [partner network][10].

### 🐳 Docker Installation (Recommended for Development)

For quick setup with Docker:

```bash
# Clone the repository (if not already done)
git clone -b MOODLE_501_STABLE git://git.moodle.org/moodle.git
cd moodle

# Start with Docker Compose
docker compose up -d --build

# Wait 10-15 minutes for automatic installation
docker compose logs -f moodle

# Access Moodle at http://localhost:9000
# Default credentials: admin / Admin@123
```

**See detailed guides:**
- [QUICKSTART.md](QUICKSTART.md) - Get started in 5 minutes
- [DOCKER_README.md](DOCKER_README.md) - Complete documentation
- [.env.production.example](.env.production.example) - Production deployment

**Features:**
- ✅ Automatic installation via CLI
- ✅ MySQL 8.4 with optimal configuration
- ✅ PHP 8.2 with all required extensions
- ✅ Cron job running every minute
- ✅ MailHog for email testing
- ✅ phpMyAdmin for database management
- ✅ Security best practices (code not writable by web server)
- ✅ Proper directory structure (Moodle 5.1+ with /public)

## License

Moodle is provided freely as open source software, under version 3 of the GNU General Public License. For more information on our license see

[1]: https://moodle.org
[2]: https://moodle.com
[3]: https://docs.moodle.org/
[4]: https://sandbox.moodledemo.net/
[5]: https://moodledev.io
[6]: https://moodle.com/events/mootglobal/
[7]: https://moodledev.io/general/community/meetings
[8]: https://moodleassociation.org/
[9]: https://download.moodle.org
[10]: https://moodle.com/partners
[11]: https://moodle.com/cloud
[12]: https://moodledev.io/general/license
