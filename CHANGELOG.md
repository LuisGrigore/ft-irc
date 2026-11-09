# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-11-09

### Generated from commit range: `HEAD`

### Features

- [46ed3ee](https://github.com/LuisGrigore/ft-irc-final/commit/46ed3ee3ebc22fa916bd9a4fea65b78746fa7a4a) IRCService is C++98 complient and compiles with all flags Closes #17 (**FEAT-001**) [Closes #17](https://github.com/LuisGrigore/ft-irc-final/issues/17)
- [4a53ffa](https://github.com/LuisGrigore/ft-irc-final/commit/4a53ffa6767e09e4c65b4df794f7969e090a6e48) implement IRCService lifecycle methods Closes #16 (**FEAT-001**) [Closes #16](https://github.com/LuisGrigore/ft-irc-final/issues/16)
- [ef47e3a](https://github.com/LuisGrigore/ft-irc-final/commit/ef47e3a5c06c06eab844d0c0ac7be0a5341e93ff) added unit tests for IRCService lifecycle methods Closes #15 (**FEAT-001**) [Closes #15](https://github.com/LuisGrigore/ft-irc-final/issues/15)
- [24414fa](https://github.com/LuisGrigore/ft-irc-final/commit/24414facddfd6eb94843a6c9d546154dd17efbfb) ClientManager is C++98 complient and compiles with all flags after implementation of dirty client logic Closes #163 (**FEAT-001**) [Closes #163](https://github.com/LuisGrigore/ft-irc-final/issues/163)
- [ab9bcfd](https://github.com/LuisGrigore/ft-irc-final/commit/ab9bcfdf040e65c592df15155fa29bfa5e24c8ce) implement ClientManager dirty client logic Closes #162 (**FEAT-001**) [Closes #162](https://github.com/LuisGrigore/ft-irc-final/issues/162)
- [92f2e0a](https://github.com/LuisGrigore/ft-irc-final/commit/92f2e0af3abee06b755a2b00a2ea74aca9c09c45) added unit tests for ClientManager dirty client methods Closes #161 (**FEAT-001**) [Closes #161](https://github.com/LuisGrigore/ft-irc-final/issues/161)
- [8038656](https://github.com/LuisGrigore/ft-irc-final/commit/80386565e63b80a14188491cd23b9580680e61c4) NickManager is C++98 complient and compiles with all the flags Closes #14 (**FEAT-001**) [Closes #14](https://github.com/LuisGrigore/ft-irc-final/issues/14)
- [dbf4547](https://github.com/LuisGrigore/ft-irc-final/commit/dbf45471ec87ea5cff3aa94105af20d668d357c0) implement NickManager methods Closes #13 (**FEAT-001**) [Closes #13](https://github.com/LuisGrigore/ft-irc-final/issues/13)
- [5f479bc](https://github.com/LuisGrigore/ft-irc-final/commit/5f479bcf17dbf583fd46b9ec08ccb83a3524cfc5) added tests for validation in nick reserve method (**FEAT-001**)
- [4ea567b](https://github.com/LuisGrigore/ft-irc-final/commit/4ea567bc20bed40f927ab7d18ac0aed4143358d3) added NickManager unit tests Closes #12 (**FEAT-001**) [Closes #12](https://github.com/LuisGrigore/ft-irc-final/issues/12)
- [4dfe003](https://github.com/LuisGrigore/ft-irc-final/commit/4dfe00339b008389b4a6015c2a4704c80ff6e951) ClientManager is C++98 complient and compiles with all the flags Closes #11 (**FEAT-001**) [Closes #11](https://github.com/LuisGrigore/ft-irc-final/issues/11)
- [e4205b8](https://github.com/LuisGrigore/ft-irc-final/commit/e4205b8027292ef6f856a081ec63a6eda0be0028) fixed include statement in Client.cpp to be relative (**FEAT-001**)
- [da83bf3](https://github.com/LuisGrigore/ft-irc-final/commit/da83bf37265d5083e5cf3c8aa7f2ca906f9c33bc) implement ClientManager methods Closes #10 (**FEAT-001**) [Closes #10](https://github.com/LuisGrigore/ft-irc-final/issues/10)
- [7c3716a](https://github.com/LuisGrigore/ft-irc-final/commit/7c3716a785220292fced7f1e20439e4beb124f99) added ClientManager unit tests Closes #9 (**FEAT-001**) [Closes #9](https://github.com/LuisGrigore/ft-irc-final/issues/9)
- [3209bae](https://github.com/LuisGrigore/ft-irc-final/commit/3209bae6a649eaf36fd9e8b0517413823c032a8c) Client is C++98 complient and compiles with all the flags after client buffer methods implemented Closes #8 (**FEAT-001**) [Closes #8](https://github.com/LuisGrigore/ft-irc-final/issues/8)
- [dd7ccf3](https://github.com/LuisGrigore/ft-irc-final/commit/dd7ccf3eb7c380c2b91422aaa604c874bcd2ce8b) implemented client buffer methods Closes #7 (**FEAT-001**) [Closes #7](https://github.com/LuisGrigore/ft-irc-final/issues/7)
- [75bfd4b](https://github.com/LuisGrigore/ft-irc-final/commit/75bfd4b13b4abeb9cda9f80aaeb3416b4374cec2) fixed line separation in client buffer tests and added tests for \n and \r inside lines (**FEAT-001**)
- [3ebec6a](https://github.com/LuisGrigore/ft-irc-final/commit/3ebec6aa8ec058a25baa00cd42edb9f3ef8b7f41) added client buffer methods unit tests Closes #6 (**FEAT-001**) [Closes #6](https://github.com/LuisGrigore/ft-irc-final/issues/6)
- [79219a1](https://github.com/LuisGrigore/ft-irc-final/commit/79219a1cdff9d35c850adccc6e9acb2c743445e2) added setters missing tests, formatted Client unit tests in sections and refactored setClosing to correct section (**FEAT-001**)
- [4200d05](https://github.com/LuisGrigore/ft-irc-final/commit/4200d05ddc5cd8d2c137d06fcb4f57f4bb2f026f) Client is C++98 complient and compiles with all the flags Closes #5 (**FEAT-001**) [Closes #5](https://github.com/LuisGrigore/ft-irc-final/issues/5)
- [4761cab](https://github.com/LuisGrigore/ft-irc-final/commit/4761cab57f034ba8e1f87e666f423c13aefb1180) implement Client getters and setters Closes #4 (**FEAT-001**) [Closes #4](https://github.com/LuisGrigore/ft-irc-final/issues/4)
- [4cd9ad9](https://github.com/LuisGrigore/ft-irc-final/commit/4cd9ad90e1e53aa1e42faf2a6b4bbd2f79f09fb7) added client getters/setters unit tests Closes #3 (**FEAT-001**) [Closes #3](https://github.com/LuisGrigore/ft-irc-final/issues/3)
- [2e859c9](https://github.com/LuisGrigore/ft-irc-final/commit/2e859c93828b063d123ee2ff5595a4bc9486cf15) Initial commit: add README with branch documentation

### Devops

- [38ab776](https://github.com/LuisGrigore/ft-irc-final/commit/38ab776ca4426f7cbf6fbddcb352d7134cbe2a27) updated-documentation-to-reflect-FEAT-001-changes Closes #168 (**DEVOPS-002**) [Closes #168](https://github.com/LuisGrigore/ft-irc-final/issues/168)
- [04a6425](https://github.com/LuisGrigore/ft-irc-final/commit/04a64258fb511139c9330658da05981a90935ae7) implement commit.sh script Closes #165 (**DEVOPS-001**) [Closes #165](https://github.com/LuisGrigore/ft-irc-final/issues/165)
- [c5137e4](https://github.com/LuisGrigore/ft-irc-final/commit/c5137e4e0ef0c0d8cfa389c12924e60d931e6d0f) initial repo setup
- [9a50cd1](https://github.com/LuisGrigore/ft-irc-final/commit/9a50cd1c92889d6c41fe2a2e411b61fb7c8f57e0) initial repo setup
- [6b71891](https://github.com/LuisGrigore/ft-irc-final/commit/6b718919bd61d2402388aa2c30a92e3d1bcd2038) initial repo setup



### Chore

- [7760f62](https://github.com/LuisGrigore/ft-irc-final/commit/7760f6273de077ebbf4d7f8954e6498f86b37d64) update changelog
- [6d1aca0](https://github.com/LuisGrigore/ft-irc-final/commit/6d1aca05df0216280f81a9ce2cbebc4c27d0fb7a) update changelog
- [e6612c4](https://github.com/LuisGrigore/ft-irc-final/commit/e6612c44f20d3d4f4d39d0fd80ba3fbb91d801cc) update changelog
- [d6f968c](https://github.com/LuisGrigore/ft-irc-final/commit/d6f968cff2790331a27427bbde7b424ee0d298d1) refactored Client and NickManager method documentation
- [944e360](https://github.com/LuisGrigore/ft-irc-final/commit/944e360fd304648fb49a6ed5d0e9cb5e91b88cb8) update changelog



---

*Generated by `scripts/generate-changelog.sh` on 2026-11-09.*
