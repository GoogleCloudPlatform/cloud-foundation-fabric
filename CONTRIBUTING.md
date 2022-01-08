# Contributing

We welcome any contributions on bugs, or feature requests you would like to submit!

The basic process is pretty simple:

* Fork the Project
* Create your Feature Branch<br>`git checkout -b feature/AmazingFeature`
* Commit your Changes<br>`git commit -m 'Add some AmazingFeature`
* Make sure tests pass!<br>`pytest # in the root or `tests` folder`
* Make sure Terraform linting is ok (hint: `terraform fmt -recursive` in the root folder)
* Make sure any changes to variables and outputs are reflected in READMEs<br>`./tools/tfdoc.py [changed folder]`
* Push to the Branch<br>`git push origin feature/AmazingFeature`
* Open a Pull Request

When implementing your new feature, please follow our [core design principles](./MANIFESTO.md#core-design-principles).
