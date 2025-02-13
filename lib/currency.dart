import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;



// Define a list of available currencies.
const List<String> availableCurrencies = [
  'United States Dollar',
  'South Korean Won'
];

  Future<String> extractData(currency) async
  {
     if (currency == "United States Dollar") return "1";
    final response = await http.Client().get(Uri.parse('https://www.x-rates.com/table/?from=USD&amount=1'));
    if(response.statusCode == 200)
    {
      var document = parser.parse(response.body);
      var data = document.getElementsByClassName('tablesorter ratesTable')[0].children[1];
      for(int i = 0;;i++)
      {
        try
        {
          var conversion = data.children[i].text.trim().split('\n');
          if(currency == conversion[0])
          {
            return conversion[1];
          }

        }
        catch(e)
        {
          return 'Error';
        }
      }
    }
    else{
     return "Error" ;
    }  
  }


Future<double> convert(String fromCurrency, String toCurrency, double amount) async {
  String rateFrom = (fromCurrency == "United States Dollar") ? "1" : await extractData(fromCurrency);
  String rateTo = (toCurrency == "United States Dollar") ? "1" : await extractData(toCurrency);
  if (rateFrom != "Error" && rateTo != "Error") {
    // Conversion: amount in toCurrency = amount * (rateTo / rateFrom)
    return amount * double.parse(rateTo) / double.parse(rateFrom);
  } else {
    return -1.0;
  }
}


