# CANOPUS Test Harness

The Canopus Test Harness is a shell POC harness designed to enable testing of a wide variety of different languages and to be used to accentuate testing.

Why is it called Canopus you may ask?

Canopus was widely used as a navigation star by ancient mariners and now has found use again for spacecraft

Canopus:
 * Also known as Alpha Carinae, this white giant is the brightest star in the
   southern constellation of Carina and the second brightest star in the
   nighttime sky. Located over 300 light-years away from Earth, this star
   is named after the mythological Canopus, the navigator for king Menelaus
   of Sparta in The Iliad. 

 * Thought it was not visible to the ancient Greeks and Romans, the star was
   known to the ancient Egyptians, as well as the Navajo, Chinese and ancient
   Indo-Aryan people. In Vedic literature, Canopus is associated with
   Agastya, a revered sage who is believed to have lived during the 6th or
   7th century BCE. To the Chinese, Canopus was known as the "Star of the Old Man",
   and was charted by astronomer Yi Xing in 724 CE.

 * It is also referred to by its Arabic name Suhayl (Soheil in persian), which
   was given to it by Islamic scholars in the 7th Century CE. To the Bedouin
   people of the Negev and Sinai, it was also known as Suhayl, and used along
   with Polaris as the two principal stars for navigation at night.

 * It was not until 1592 that it was brought to the attention of European
   observers, once again by Robert Hues who recorded his observations of it
   alongside Achernar and Alpha Centauri in his Tractatus de Globis (1592).

 * As he noted of these three stars, "Now, therefore, there are but three Stars
   of the first magnitude that I could perceive in all those parts which are
   never seene here in England. The first of these is that bright Star in the
   sterne of Argo which they call Canobus. The second is in the end of
   Eridanus. The third is in the right foote of the Centaure."

 * This star is commonly used for spacecraft to orient themselves in space,
   since it is so bright compared to the stars surrounding it.


## Getting Started

This harness system relies on the SLCF (Shell Library Component Framework) and will not function without a link to it.  You can download the SLCF from gitlab as well at git@sig-gitlab.internal.synopsys.com:klusman/ShellLibrary.git.  Please follow the settings to ensure it is enable and available in the shell.

### Prerequisites

Installation can be handled via the `setup.sh` file.  This will set the necessary environment settiing so long as they exist.

## Running Tests

The Canopus system also has its own library of unit tests (currently under development).  This will allow the CANOPUS Test Harness to run against itself to validate basic functionality. 

## Contributing

Please read [CONTRIBUTING](CONTRIBUTING.md) for details on code of conduct and the process for submitting pull requests.

## Versioning

Current Version is 2.01

Each minor revisioning is based on functionality provided into the run harness.  The SLCF versioning likely will run "faster".

## RoadMap

* CANOPUS-3.0

This release will include fixes for updates to support xml and json input formats in a concise and "object-oriented" way.  It will also include integration with completed SLCF libraries.  Dependency management will be fixed.

## Authors

* **Michael Klusman**

## License

This project is licensed under the MIT License

## Acknowledgments

