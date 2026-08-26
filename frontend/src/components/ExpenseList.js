import React from 'react';

function ExpenseList({ expenses, onDeleteExpense }) {
  return (
    <div>
      <h2>Expenses</h2>
      {expenses.length === 0 ? (
        <p>No expenses yet</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Category</th>
              <th>Amount</th>
              <th>Description</th>
              <th>Date</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {expenses.map((expense) => (
              <tr key={expense.id}>
                <td>{expense.category}</td>
                <td>${expense.amount}</td>
                <td>{expense.description}</td>
                <td>{expense.date}</td>
                <td>
                  <button onClick={() => onDeleteExpense(expense.id)}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default ExpenseList;