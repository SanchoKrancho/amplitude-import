# Amplitude Backfill Importer

This is a script to backfill data in an Amplitude project based on a project export. See https://amplitude.zendesk.com/hc/en-us/articles/206404358-Self-Data-Backfill-Guide for their primer on the subject.

## USAGE

### Preparing data
- Export the data you want to import from Amplitude's project detail pane
- Unzip the data file and concatenate it:
```
unzip -p <src>.zip | gunzip -c > <target>.json
```

### Get an API key
- For the project you want to import to. It's recommended to run the import against a test project first (assuming you have the bandwidth under your monthly events cap)

### Run the import
- Install dependencies:
```
bundle install
```
- Run the script:
```
API_KEY=<your API key> bundle exec ruby sample_import.rb <target>.json
```
