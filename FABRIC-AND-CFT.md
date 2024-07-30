# Cloud Foundation Fabric and Cloud Foundation Toolkit

This page highlights the main differences (both technical and philosophical) between Cloud Foundation Fabric and Cloud Foundation Toolkit for end users, to guide them in their decision making process for identifying the best suite of modules for their use cases.

## Cloud Foundation Fabric (a.k.a Fabric, this repo)

Fabric is a collection of Terraform modules and end-to-end examples meant to be cloned as a single unit and used as is for fast prototyping or decomposed and modified for usage in organizations. Fabric also provides a robust implementation of foundation [stages](./fast/stages), offering a more complete blueprint for organizations to build upon.

## Cloud Foundation Toolkit (a.k.a CFT)

CFT is a collection of Terraform modules and examples with opinionated GCP best practices implemented as individual modules for gradual adoption and off the shelf usage in organizations. CFT also includes an IaC [foundation repository](https://github.com/terraform-google-modules/terraform-example-foundation), though it's less developed compared to Fabric's.

## Key Differences

<table>
  <tr>
   <td>
   </td>
   <td><strong>Fabric (FAST)</strong>
   </td>
   <td><strong>CFT (Cloud Foundation Toolkit)</strong>
   </td>
  </tr>
  <tr>
   <td><strong>Target User</strong>
   </td>
   <td>Organizations interested in forking, maintaining, and customizing Terraform modules to have fine-grained control over their infrastructure.
   </td>
   <td>Organizations interested in using opinionated, prebuilt Terraform modules with a focus on Google Cloud best practices.
   </td>
  </tr>
  <tr>
   <td><strong>Configuration</strong>
   </td>
   <td>Less opinionated, allowing end users higher flexibility and often offering more configuration options within a single module.
   </td>
   <td>Opinionated by default, end users may need to fork if it doesn't fully meet their use case.  Often requires composing multiple modules for complex configurations.
   </td>
  </tr>
  <tr>
   <td><strong>Extensibility</strong>
   </td>
   <td>Built with extensibility in mind, catering to fork and use patterns. Modules are often lightweight and easy to adopt / tailor to specific use cases.
   </td>
   <td>Not primarily built for fork-and-use extensibility, catering primarily to off-the-shelf consumption. Modules are tailored towards common use cases and extensible via composition.
   </td>
  </tr>
  <tr>
   <td><strong>Config Customization</strong>
   </td>
   <td>Prefer customization using variables via objects, providing a tight but comprehensive variable space within modules.
   </td>
   <td>Prefer customization using variables via primitives, which can lead to more modularity but may require using multiple modules for customization.
   </td>
  </tr>
  <tr>
   <td><strong>Examples</strong>
   </td>
   <td>Thorough examples for individual modules and end-to-end examples composing multiple modules, covering a wide variety of use cases from foundations to solutions. 
   </td>
   <td>Examples for a module mostly focus on that individual module. Composition is often not shown in examples but in larger modules built using smaller modules.
   </td>
  </tr>
  <tr>
   <td><strong>Resources</strong>
   </td>
   <td>Modules often encapsulate a broader set of resources, providing more functionality within a single unit.
   </td>
   <td>Heavier root modules often compose leaner sub-modules wrapping resources, which can lead to more granular control but potentially increased complexity.
   </td>
  </tr>
  <tr>
   <td><strong>Resource Grouping</strong>
   </td>
   <td>Generally grouped by logical entities, aiming for a more holistic approach to resource management.
   </td>
   <td>Generally grouped by products/product areas, aligning with Google Cloud's service organization. 
   </td>
  </tr>
  <tr>
   <td><strong>Release Cadence</strong>
   </td>
   <td>Modules versioned and released together, ensuring consistency across the framework.
   </td>
   <td>Modules versioned and released individually, allowing for more frequent updates to specific modules.
   </td>
  </tr>
  <tr>
   <td><strong>Individual module usage</strong>
   </td>
   <td>Individual modules consumed directly using Git as a module source.
<p>
For production usage, customers are encouraged to “fork and own” their own repository.
   </td>
   <td>Individual repositories consumed via the Terraform registry.
<p>
For production/airgapped usage, customers may also mirror modules to a private registry.
   </td>
  </tr>
  <tr>
   <td><strong>Factories</strong>
   </td>
   <td>Fabric implements several "factories" in modules, where users can drive or automate Terraform via YAML files (projects, subnetworks, firewalls, etc.). This simplifies common tasks and provides an alternative to pure Terraform configuration.
   </td>
   <td>CFT does not implement factories and generally shows examples usable with variable definitions files (.tfvars).
   </td>
  </tr>
   <tr>
   <td><strong>Variable Granularity</strong>
   </td>
   <td>Offers a wider range of variables within a single module for greater flexibility. For example, a single FAST module might handle project creation with extensive customization options.
   </td>
   <td>Typically requires combining multiple modules to achieve similar configuration options. Achieving the same level of project customization in CFT might involve multiple modules.
   </td>
  </tr>
  <tr>
   <td><strong>Organizational Adoption</strong>
   </td>
   <td>Mono repo cloned into an organizational VCS (or catalog) and separated into individual modules for internal consumption.
   </td>
   <td>Individual repos forked (for air gap) or wrapping upstream sources to create individual modules for internal consumption.
   </td>
  </tr>
  <tr>
   <td><strong>Distribution</strong>
   </td>
   <td>Distributed via Git/GitHub.
   </td>
   <td>Distributed via Git/GitHub and Terraform Registry.
   </td>
  </tr>
  <tr>
   <td><strong>Testing</strong>
   </td>
   <td>Every PR performs unit tests on modules, examples, and documentation snippets by evaluating a Terraform plan via Python <a href="https://pypi.org/project/tftest/">tftest</a> library.
   </td>
   <td>Every PR performs full end-to-end deployment with integration tests using the <a href="https://pkg.go.dev/github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test">blueprint test framework</a>.
   </td>
  </tr>
</table>

## Similarities

* Both collections of modules are designed with stable interfaces that work well together with other modules in their ecosystem.
* Both collections of modules require minimal variables and provide defaults.
* Both collections of modules are well tested and documented with information about usage, code snippets and provide information about variables and outputs.

## Should you choose Fabric or CFT?

> You/Your organization is knowledgeable in Terraform and interested in forking and owning a collection of modules.
  
  Fabric is a better choice as it bootstraps you with a collection of modules out of the box that can be customized exactly to fit your organization needs.

> You/Your organization is getting started with Terraform and interested in GCP best practices out of the box.

  CFT is a better choice as it allows you to directly reference specific modules from the registry and provide opinionated configuration by default.

> You/Your organization is looking to rapidly prototype some functionality on GCP.
  
  Fabric is a better choice. Being a mono repo it allows you to get started quickly with all your source code in one place for easier debugging.

> You/Your organization has existing infrastructure and processes but want to start adopting IaC gradually.
  
  CFT is designed to be modular and off the shelf, providing higher level abstractions to product groups which allows certain teams to adopt Terraform without maintenance burden while allowing others to follow existing practices.

## Using Fabric and CFT together

Even with all the above points, it may be hard to make a decision. While the modules may have different patterns and philosophies, it is often possible to bring the best of both worlds together. Here are some tips to follow:

* Since modules work well together within their ecosystem, select logical boundaries for using Fabric or CFT. For example use CFT for deploying resources within projects but use Fabric for managing project creation and IAM.
* Use strengths of each collection of modules to your advantage. Empower application teams to define their infrastructure as code using off the shelf CFT modules. Using Fabric, bootstrap your platform team with a collection of tailor built modules for your organization.
* Lean into module composition and dependency inversion that both Fabric and CFT modules follow. For example, you can create a GKE cluster using either [Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/gke-cluster-standard#gke-cluster-module) or [CFT](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine) GKE module and then use either [Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/gke-hub#variables) or [CFT](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/fleet-membership) for setting up GKE Hub by passing in outputs from the GKE module.
