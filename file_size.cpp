#include <iostream>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <boost/range/adaptors.hpp>
#include <boost/range/algorithm.hpp>
#include <boost/range/algorithm_ext/push_back.hpp>
#include <boost/algorithm/string/case_conv.hpp>

namespace fs = std::experimental::filesystem;

int main()
{
	std::vector<fs::path> files;
	std::vector<std::string> exclude_exts{".erfh5", ".dsy", ".fdb", ".tit", ".vdb", 
		".pc", ".fai", ".inp", ".asc", ".dyn", ".key"};

	// populate files
	for (auto& file : fs::recursive_directory_iterator{ "Z:/HOST/models" }) {
		if (fs::is_regular_file(file) &&
			boost::find_if(exclude_exts,
				[ext = boost::to_lower_copy(file.path().extension().string())]
		(const auto& a) { return a == ext; })
			== exclude_exts.end()) {
			auto pos = std::upper_bound(files.begin(), files.end(), file,
				[](const auto& a, const auto& b) {
				return fs::file_size(a) > fs::file_size(b); });

			if (pos - files.begin() < 10) {
				files.insert(pos, file);
				if (files.size() > 10)
					files.resize(10);
			}
		}
	}

	// output
	boost::copy(files | boost::adaptors::transformed([](const auto& x) {
		return std::to_string(fs::file_size(x) / 1'000'000) + " MB\t" + x.string(); }),
		std::ostream_iterator<std::string>(std::ofstream("1.txt"), "\n"));
}
