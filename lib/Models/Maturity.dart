// information about the Arrear which will be rendered in datagrid.
class Maturity {
  /// Creates the Arrear class with required details.
  Maturity(
    this.id,
    this.branch,
    this.names,
    this.phoneNumber,
    this.loanProduct,
    this.loanAmount,
    this.maturityDate,
  );

  /// Id of an Arrear.
  final String id;
  final String branch;
  final String names;
  final String phoneNumber;
  final String loanProduct;
  final String loanAmount;
  final String maturityDate;

  //fromjson
  factory Maturity.fromJson(Map<String, dynamic> json) {
    return Maturity(
      json['customer_id'].toString(),
      json['branch_name'].toString(),
      json['names'].toString(),
      json['phone'].toString(),
      json['product_name'].toString(),
      json['amount_disbursed'].toString(),
      json['maturity_date'].toString()
    );
  }
}
