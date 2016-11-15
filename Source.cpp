#include <iostream>
#include <vector>
#include <assert.h>
#include <algorithm>
#include <limits.h>

using namespace std;

namespace range
{
	template<typename cont, typename FUNC>
	typename cont::iterator_type upper_bound(const cont& c, FUNC pred)
	{
		return upper_bound(c.begin(), c.end(), 0, pred);
	}

	class iota
	{
		class iter : public iterator<random_access_iterator_tag, int>
		{
			int value;

		public:
			iter(int _value) : value(_value) {}
			int operator*() { return value; }
			iter operator++() { ++value; return *this; }
			iter operator++(int) { iter temp(*this); ++value; return temp; }
			bool operator!=(iter rhs) { return value != rhs.value; }
			bool operator<(iter rhs) { return value < rhs.value; }
			void operator+=(int count) { value += count; }
			int operator-(iter rhs) { return value - rhs.value; }
		};

	public:
		using iterator_type = iter;
		using const_iterator_type = const iter;

	private:
		iterator_type iter_start;
		iterator_type iter_end;

	public:
		iota(int start, int end) : iter_start(start), iter_end(end) {}
		iterator_type begin() { return iter_start; }
		iterator_type end() { return iter_end; }
		const_iterator_type begin() const { return iter_start; }
		const_iterator_type end() const { return iter_end; }
	};
}






// SRM 169 - 500 pts

vector<int> cabinets;
int workers;

bool is_success(int val)
{
	int count = 0;
	size_t ind = 0;

	while (count < workers && ind < cabinets.size())
	{
		for (int cur_sum = 0; ind < cabinets.size() && cur_sum + cabinets[ind] <= val; ++ind)
			cur_sum += cabinets[ind];

		++count;
	}

	return ind == cabinets.size();
}

bool comp(int a, int b)
{
	bool a_res = is_success(a);
	bool b_res = is_success(b);

	if (a_res == b_res)
		return false;

	return a_res < b_res;
}

class FairWorkload
{
public:
	static int getMostWork(vector<int> _cabinets, int _workers)
	{
		cabinets = _cabinets;
		workers = _workers;
		return *range::upper_bound(range::iota(0, INT_MAX), comp);
	}
};

int main()
{
	assert(170 == FairWorkload::getMostWork(vector<int>{ 10, 20, 30, 40, 50, 60, 70, 80, 90 }, 3));
	assert(110 == FairWorkload::getMostWork(vector<int>{ 10, 20, 30, 40, 50, 60, 70, 80, 90 }, 5));
}
